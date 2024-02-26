---
layout: post
title:  "Rinha de Backend 2024 - F#"
tags: portuguese fsharp dotnet
categories: hacking fsharp
---

A [Rinha de Backend](https://github.com/zanfranceschi/rinha-de-backend-2024-q1) é um evento organizado pelo [Francisco Zanfrancheschi](https://linktr.ee/zanfranceschi). As regras são simples, você precisa criar uma API rodando em docker compose, seguindo a arquitetura mínima pedida, e que sobreviva a um teste de carga previamente escrito.

![alt text](/assets/rinha-2024-q1/image.png)

Eu novamente estou participando, e novamente estou fazendo em F#. O repositório com o projeto está no GitHub:

> [Rinha de Backend 2024 - FSharp](https://github.com/vhogemann/rinha-de-backend-2024-fsharp)

Crébito
=======

O tema desse ano foi controle de concorrência, criar uma API com dois endpoints:

- Saldo e extrato `GET /clientes/{id}/extrato`
- Débito e crédito `POST /clientes/{id}/transacoes`

Tudo que você tem que fazer é garantir que a sua API, com no mínimo duas instâncias, garanta a consistência das transações sem deixar que o saldo do usuário estoure o limite.

## Garantindo a consistência

O maior problema dessa ediçao da Rinha é garantir que as transações sejam consistentes. O esquema mínimo da persistência pede por duas entidades: `Saldo` e `Transação`.

Saldo é o valor atual da conta do cliente, e transação é a lista de operações de débito e crédito aplicadas a conta.

![alt text](/assets/rinha-2024-q1/DDL.png)

Precisamos garantir duas coisas:

- Que o `saldo - limite` nunca seja **negativo**
- Que transações inválidas não sejam salvas na tabela

Tudo isso enquanto garantimos que a performance da API seja a melhor possível.

Escolhi usar [PostgreSQL](https://www.postgresql.org/) como banco de dados. O DDL completo está [aqui](https://github.com/vhogemann/rinha-de-backend-2024-fsharp/blob/main/src/bootstrap.sql).

### Saldo

Eu não sou nenhum mago do SQL, então a estragégia aqui é a mais simples possível. Uma `constraint` do tipo `CHECK` que garante que o saldo nunca seja negativo.


```sql
-- UNLOGGED TABLE é uma tabela que não é escrita no WAL, o que
-- significa que não pode participar de transações.
CREATE UNLOGGED TABLE balance (
    id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    amount INT NOT NULL,
    overdraft_limit INT NOT NULL,
-- Garante que o "saldo - limite" nunca seja negativo
    CONSTRAINT amount_overdraft_limit_check CHECK (amount + overdraft_limit >= 0),
    CONSTRAINT balance_client_id_id_key UNIQUE (client_id, id)
);
CREATE INDEX balance_client_id_idx ON balance (client_id);
```

### Transação

As duas tabelas que eu tenho, `balance` e `transactions`, são criadas como `UNLOGGED TABLE`. Isso aumenta a performance já que o PostgreSQL não precisa escrever essas tabelas no `WAL` (Write Ahead Log), que é um arquivo de log que o PostgreSQL usa pra garantir a consistência dos dados.

A desvantagem é que essas tabelas não podem participar de transações, então pra garantir a integrigade entre as duas a **ordem** das operações é importante.

Outra coisa que ajuda a performance é agrupar as operações de atualizar o saldo e salvar a transação em uma única chamada. Isso também é crítico pra garantir a consistência dos dados.

Pra isso, as duas operações são feitas dentro de uma `STORED PROCEDURE` que é chamada pela API:

```sql
CREATE OR REPLACE PROCEDURE withdrawal(a_client_id INT, w_amount INT, w_description TEXT) AS $$
BEGIN
-- Se a constraint for violada, a PROC para aqui e o saldo não é
-- atualizado, nem a transação é salva
    UPDATE balance
    SET amount = amount - w_amount
    WHERE client_id = a_client_id;

    INSERT INTO transactions (client_id, amount, transaction_type, transaction_date, description)
    VALUES (a_client_id, w_amount, 'WITHDRAWAL', NOW(), w_description);
END;
$$ LANGUAGE plpgsql;
```

Caso a chamada pra `withdrawal` falhe, eu capturo a exceção e retorno `422` na API.

## Minha implementação em F#

Assim como eu fiz na [minha última participação](https://github.com/vhogemann/rinha-de-backend-2023) na [Rinha de 2023](https://github.com/zanfranceschi/rinha-de-backend-2023-q3), escolhi fazer tudo em [F#](https://fsharp.org).

F# é uma linguagem funcional, multi-paradigma, que roda em cima do Dotnet CLR. Ela foi criada por [Don Syme](https://mastodon.sdf.org/@dsyme) na Microsoft, e pertence a família [ML](https://en.wikipedia.org/wiki/ML_(programming_language)) de linguagens de programação funcionais, assim como o [OCaml](https://ocaml.org/).

Esse artigo tem um bom [resumo das diferenças entre F# e OCaml](https://jkone27-3876.medium.com/comparing-ocaml-to-f-f75e4ab27769).

Um dos méritos do F# é ser bem expressivo, e bastante enxuto, então [a implementação da API](https://github.com/vhogemann/rinha-de-backend-2024-fsharp/blob/main/src/Rinha/Program.fs) inteira ficou em menos de 200 linhas de código. O que eu vou fazer aqui nesse aquivo é um code-review de cada módulo como forma de apresentar o F# pra vocês.

Eu vou omitir algums imports pra facitar a leitura, e incluir comentários que não estão no fonte, mas a maior parte do código vai estar aqui.

### Modelo

Aqui eu defino os DTOs que a aplicação vai usar. Como mais na frente você vai ver que eu estou usando SQL direto, não preciso me preocupar em separar o que vai pra View e o que vai pro Banco.

Uma coisa que vale a pena explicar aqui sobre F# é que ele tem o conceito de **módulos**. Módulos são usados pra organizar *funções*, *tipos* e *valores* relacionados.

Módulos são diferentes de **namespaces**, que também existem em C#, porquê esses não suportam funçoes nem valores, só declaracão de tipos ou **módulos**. Um módulo funciona mais ou menos como uma classe estática, onde tudo que é declarado vira uma propriedade pública.

Os **DTOs** declarados nesse módulo são *records*. Em F# records diferem de classes por:
- Imutáveis por padrão, uma vez criados não podem ser mudados
- Tem igualdade estrutural, dois *record* são iguais se todas as propriedades forem iguais
- Pode ser usados em *pattern matching* pra desmembrar e comparar todos os seus campos

```fsharp
module Model =
    // F# é compatível com C#, então podemos usar o pacote
    // System.Text.JSON padrão do Dotnet pra serialização
    let options = JsonSerializerOptions()
    // Configuração da serialização em JSON pra usar `snake_case`
    // esse objeto `options` vai ser usado lá na frente pelos
    // controllers
    options.PropertyNamingPolicy <- JsonNamingPolicy.SnakeCaseLower
    
    // View object pra receber as requisições de débito/crédito
    type TransacaoRequest =
        { valor: int
          tipo: string
          descricao: string }

    // Resposta pra uma transação de débito/crédito
    type TransacaoResponse = { limite: int; saldo: int }

    // Os tipos list, array, map, option e outros podem ser
    // declarados como <Tipo do Item> list
    type ExtratoResponse =
        { saldo: ExtratoSaldoResponse
          ultimasTransacoes: ExtratoTransacaoResponse list }

    // Em F# você precisa declarar os tipos antes de poder
    // referenciar eles. Mas você pode usar `and` pra
    // encadear as declarações e ajudar um pouco na hora
    // de ler o código.       
    and ExtratoSaldoResponse =
        { limite: int
          total: int
          dataExtrato: DateTime }
    and ExtratoTransacaoResponse =
        { valor: int
          tipo: string
          descricao: string
          realizadaEm: DateTime }
```


### Persistência

Eu estou usando [PostgreSQL](https://www.postgresql.org/) como banco de dados, e um wrapper F# para [ADO.Net](https://learn.microsoft.com/en-Us/dotnet/framework/data/adonet/) chamado [Donald](https://github.com/pimbrouwers/Donald) que oferece uma API funcional em cima da API normal em C#.

A primeira coisa é declarar um novo módulo `Persistence`, e declarar algumas funções que vão receber um `IDataReader`, que é um helper pra ler os dados do `resultset` que vem do banco e retornar um dos DTOs declarados em `Model`.

```fsharp
module Persistence =
    open Donald
    open Model // Modulo onde declaramos os DTOs
    
    let transacaoResposneDataReader (rd: IDataReader) : TransacaoResponse =
         { saldo = rd.ReadInt32 "amount" 
           limite = rd.ReadInt32 "overdraft_limit" }
    let balanceDataReader (rd: IDataReader) : ExtratoSaldoResponse =
        { total = rd.ReadInt32 "amount"
          limite = rd.ReadInt32 "overdraft_limit"
          dataExtrato = DateTime.Now }
    
    // Pattern Matching para mapear o tipo da transação que vem do banco
    // como "DEPOSIT"/"WITHDRAWAL" e precisa ser retornada como "c"/"d" na API
    let tipoMapper =
        function
        | "DEPOSIT" -> "c"
        | "WITHDRAWAL" -> "d"
        | _ -> "?"

    let transactionDataReader (rd: IDataReader) : ExtratoTransacaoResponse =
        { valor = rd.ReadInt32 "amount"
          tipo = rd.ReadString "transaction_type" |> tipoMapper
          descricao = rd.ReadString "description"
          realizadaEm = rd.ReadDateTime "transaction_date" }
```

Agora eu declaro duas funções, `withdrawal` pra débitos e `deposit` pra créditos.

Eu estou usando `Npgsql` como driver pra PostgreSQL, e o `Donald` tem um módulo `Db` que oferece uma API funcional pra criar comandos, setar parâmetros, e executar queries.

Em F# você pode usar o *forward pipe* `|>` pra passar o resultado de uma função como argumento pra outra, o que deixa o código mais legível.

Um truque que eu usei aqui foi declarar mais de um statement SQL em cada query. Assim eu consigo fazer a transação de débito/crédito e já retornar o saldo atualizado em uma única chamada.

A última chamada de cada função é pra `Db.Async.querySingle`, que é uma função que executa a query e retorna um único resultado. O `transacaoResposneDataReader` que eu declarei lá em cima é usado pra mapear o resultado do banco pra um dos DTOs.

```fsharp
    let withdrawal (dbconn: NpgsqlConnection) (clientId: int, amount: int, description: string) =
        let sql =
            "CALL withdrawal(@clientId, @amount, @description);
             SELECT amount, overdraft_limit FROM balance WHERE client_id = @clientId;"
        let parameters =
            [ "@clientId", sqlInt32 clientId
              "@amount", sqlInt32 amount
              "@description", sqlString description ]
        dbconn
        |> Db.newCommand sql
        |> Db.setParams parameters
        |> Db.Async.querySingle transacaoResposneDataReader
```

O controle de concorrência é feito pelo PostgreSQL, a `STORED PROCEDURE` responsável pelo débito (`withdrawal`) cria uma transação e depende de uma `CONSTRAINT` do tipo `CHECK` pra garantir que o saldo não fique negativo.


```fsharp
    let deposit (dbconn: NpgsqlConnection) (clientId: int, amount: int, description: string) =
        let sql =
            "CALL deposit(@clientId, @amount, @description);
             SELECT amount, overdraft_limit FROM balance WHERE client_id = @clientId;"
        let parameters =
            [ "@clientId", sqlInt32 clientId
              "@amount", sqlInt32 amount
              "@description", sqlString description ]
        dbconn
        |> Db.newCommand sql
        |> Db.setParams parameters
        |> Db.Async.querySingle transacaoResposneDataReader
```

Finalmente eu declaro duas funções para pegar o saldo e as últimas transações do cliente, que eu combino no `Controller` pra retornar o extrato.

```fsharp
    let getBalance (dbconn: NpgsqlConnection) (clientId: int) =
        let sql = "SELECT amount, overdraft_limit FROM balance WHERE client_id = @clientId"
        let parameters = [ "@clientId", sqlInt32 clientId ]
        dbconn
        |> Db.newCommand sql
        |> Db.setParams parameters
        |> Db.Async.querySingle balanceDataReader

    let getTransactions (dbconn: NpgsqlConnection) (clientId: int) =
        let sql =
            """
            SELECT amount, transaction_type, description, transaction_date 
            FROM transactions 
            WHERE client_id = @clientId
            ORDER BY transaction_date DESC LIMIT 10
            """
        let parameters = [ "@clientId", sqlInt32 clientId ]
        dbconn
        |> Db.newCommand sql
        |> Db.setParams parameters
        |> Db.Async.query transactionDataReader
```

### Controllers

Pra implementar a API REST eu estou usando uma biblioteca chamada [Falco](https://www.falcoframework.com/) que reutiliza componentes do [ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/introduction-to-aspnet-core?view=aspnetcore-8.0) e oferece uma API funcional em F#.

As duas primeiras funções que eu declaro utilizam dois tipos de [monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)): `Option` e `Result`.

A forma preferida de lidar com `Null` em F# é através do tipo `Option`, que pode ter dois valores: `Some <T>` e `None`.

E `Result` é utilizado pra representar o resultado de alguma operação, também tendo dois valores: `Ok <T>` e `Error <Exception>`. 

```fsharp
module Controller =
    open Model
    
    let optionToResponse (res: 'a option) =
        match res with
        | Some x -> Response.ofJsonOptions options x
        | None -> Response.withStatusCode 404 >> Response.ofEmpty

    let deserialize ctx = task {
        try
            let! obj = Request.getJsonOptions options ctx
            return Ok obj
        with ex ->
            return Error ex
        }
```

`Services.inject` é uma função do `Falco` que apresenta a funcionalidade de *dependency injection* do ASP.NET Core de forma funcional. 

No caso abaixo, `Services.inject<NpsqlConnection>` recebe como parâmetro uma função, cujo parâmetro `dbconn` é injetado com uma instância da conexão com o banco de dados.

A sintaxe `fun parametros -> ...` é como você declara um `lambda`, ou função anônima, em F#.

O bloco `task { ... }` é uma `computational expression`, que é uma feature do F#. Expressões computacionais oferecem uma forma de abstrair detalhes de uma computação para que você possa se concentrar na lógica.

Nesse caso a expressão `task { ... }` retorna um `System.Threading.Task` do Dotnet. É a versão do F# do `async/await` do C#, sendo que o F# implementou esse conceito primeiro.

Tem uma série de tutoriais muito bons que explica o funcionamento de expressões computacionais no site [F# For fun and profit](https://fsharpforfunandprofit.com/series/computation-expressions/).

Abaixo a função que retorna o extrato:

```fsharp
    let balance =
        Services.inject<NpgsqlConnection> (fun dbconn ->
            fun ctx ->
            // "task" é como se lida com async em F#
                task {
                    let clientId = (Request.getRoute ctx).GetInt "id" |> int
            // "let!" bloqueia até que o valor esteja disponível
                    let! mayBeSaldo = Persistence.getBalance dbconn clientId
                    let! transacoes = Persistence.getTransactions dbconn clientId
                    return
                        mayBeSaldo
                        |> Option.map (fun saldo ->
                            { saldo = saldo
                              ultimasTransacoes = transacoes })
                        |> optionToResponse <| ctx
                })
```
E aqui é a função que faz as transações, que é a mais complexa. Ela faz a validação do payload, e chama a função de débito ou crédito dependendo do tipo da transação.

Uma coisa que provavélmente eu deveria melhorar aqui é que eu dependo da exceção pra retornar um erro `422` caso a transação estoure o limite do cliente. Essa exceção vem lá do PostgreSQL na minha *STORED PROCEDURE*, e existem formas de tratar o erro no próprio SQL e retornar um erro mais amigável.

```fsharp
    let transaction =
        Services.inject<NpgsqlConnection> (fun dbconn ->
            fun ctx ->
                task {
                    let clientId = (Request.getRoute ctx).GetInt "id"
                    let! request = deserialize ctx
                    match request with
                    | Error _ -> return (Response.withStatusCode 422 >> Response.ofPlainText "Bad Request") ctx
                    | Ok request ->
                    // Outro ponto que eu poderia melhorar...
                    // Tudo isso aqui poderia estar em uma função declarada lá em cima
                    // no módulo Model... ¯\_(ツ)_/¯
                    if request.valor <= 0 || request.descricao = null || request.descricao.Length > 10 || request.descricao.Length = 0 then
                        return (Response.withStatusCode 422 >> Response.ofPlainText "Bad Request") ctx
                    else
                    // GO HORSE PROGRAMMING
                    // Aqui eu trato a exception que pode vir do banco caso
                    // a constraint seja violada
                    try
                        let! response =
                        // Pattern matching!
                            match request.tipo with
                            | "c" -> Persistence.deposit dbconn (clientId, request.valor, request.descricao) // Credito
                            | "d" -> Persistence.withdrawal dbconn (clientId, request.valor, request.descricao) // Debito
                            | _ -> failwith "Invalid transaction type"
                        return response |> optionToResponse <| ctx
                    with _ ->
                        return (Response.withStatusCode 422 >> Response.ofEmpty) ctx
                })
```

### Routing

Finalmente o ponto de entrada do programa. Aqui o `Falco` oferece uma API funcional pra configurar o servidor.

```fsharp
// "EntryPoint" diz ao compilador que essa função é o ponto de entrada do aplicativo
[<EntryPoint>]
let main args = // Função "main" semelhante a C/C++/C#/Java
    let env = Environment.GetEnvironmentVariable "ASPNETCORE_ENVIRONMENT"
    let config = configuration [||] {
        required_json "appsettings.json"
        optional_json $"appsettings.{env}.json"
    }
    webHost args {
        // Configura a injeção de dependência, adicionando a conexão com o banco
        add_service (_.AddNpgsqlDataSource(config.GetConnectionString("Default")))

        // Configura os endpoints
        // Controller.transaction e Controller.balance foram declaradas no modulo
        // Controller lá em cima
        endpoints
            [ post "/clientes/{id}/transacoes" Controller.transaction
              get "/clientes/{id}/extrato" Controller.balance ]
    }

    0 // A função main precisa retornar um inteiro
```
# Testes

Abaixo os resultados do teste de carga. Eu acho que a performance está excelente pra um projeto onde eu coloquei muito pouco esforço em otimizar qualquer coisa.

![alt text](/assets/rinha-2024-q1/gatling.png)

Os resultados completos você pode ver [aqui](/assets/rinha-2024-q1/gatling/index.html).

# Conclusão

Se você chegou até aqui, muito obrigado! Espero que você tenha gostado de conhecer um pouco mais sobre F#. É minha linguagem de programação favorita, e a melhor linguagem da qual você nunca ouviu falar!