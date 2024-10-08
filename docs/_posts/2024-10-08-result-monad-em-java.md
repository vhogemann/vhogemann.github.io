---
layout: post  
title: "Escrevendo o Monad `Result` do Zero em Java"  
tags: java monad programacao-funcional  
image: /assets/result-monad-java.png  
---

![Escrevendo o Monad `Result` do Zero em Java](/assets/result-monad-java.png)

### Escrevendo o Monad `Result` do Zero em Java

Nesse artigo, a gente vai passar pelo processo de criar um Monad `Result` em Java. A classe `Result` é uma classe utilitária feita pra encapsular o resultado de uma operação que pode dar certo ou errado. Ela guarda ou um valor do tipo `V` ou uma exceção indicando um erro. Essa classe é útil pra lidar com operações que podem dar certo ou falhar, oferecendo uma maneira clara e funcional de gerenciar os estados de sucesso e erro.

#### 1. Definindo a Classe `Result`

Primeiro, vamos definir a classe `Result` com dois campos: `value` e `error`. Esses campos vão guardar o resultado bem-sucedido e a exceção, respectivamente.

```java
package com.hogemann.monad;

public class Result<V> {

    private final V value;
    private final Exception error;

    private Result(V value, Exception error) {
        this.value = value;
        this.error = error;
    }
}
```

#### 2. Adicionando Métodos Estáticos

Agora, vamos adicionar métodos estáticos pra criar instâncias da classe `Result`. Esses métodos funcionam como funções que encapsulam um valor ou um erro no contexto do `Result`.

- `ok(V value)`: Cria uma instância de `Result` representando uma operação bem-sucedida.
- `error(Exception error)`: Cria uma instância de `Result` representando uma operação com falha.
- `empty()`: Cria uma instância vazia de `Result`, sem valor ou erro.

```java
public static <V> Result<V> ok(V value) {
    return new Result<>(value, null);
}

public static <V> Result<V> error(Exception error) {
    return new Result<>(null, error);
}

public static <V> Result<V> empty() {
    return new Result<>(null, null);
}
```

#### 3. Adicionando Métodos de Instância

Vamos adicionar métodos de instância pra pegar o valor ou o erro e pra checar o estado do `Result`.

- `get()`: Retorna o valor se a operação deu certo.
- `error()`: Retorna a exceção se a operação falhou.
- `isOk()`: Verifica se a operação foi bem-sucedida.
- `isEmpty()`: Verifica se o resultado tá vazio.

```java
public V get() {
    return this.value;
}

public Exception error() {
    return this.error;
}

public boolean isOk() {
    return this.error == null && this.value != null;
}

public boolean isEmpty() {
    return this.value == null && this.error == null;
}
```

#### 4. Adicionando Operações de Mônada

Pra fazer da classe `Result` um Monad, precisamos adicionar os métodos `map` e `flatMap`. Esses métodos permitem encadear operações enquanto mantém o contexto.

- `map(Function<V,U> mapper)`: Transforma o valor usando a função passada se a operação foi bem-sucedida.
- `flatMap(Function<V,Result<U>> mapper)`: Transforma o valor em outro `Result` usando a função passada se a operação deu certo.

```java
public <U> Result<U> map(Function<V, U> mapper) {
    if (isOk()) {
        return ok(mapper.apply(value));
    } else {
        return error(error);
    }
}

public <U> Result<U> flatMap(Function<V, Result<U>> mapper) {
    if (isOk()) {
        return mapper.apply(value);
    } else {
        return error(error);
    }
}
```

#### 5. Adicionando Métodos Utilitários

Por fim, a gente vai adicionar um método utilitário pra executar ações de acordo com o resultado da operação.

- `ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer)`: Executa o consumer certo dependendo se a operação foi bem-sucedida ou não.

```java
public void ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer) {
    if (isOk()) {
        consumer.accept(value);
    } else {
        errorConsumer.accept(error);
    }
}
```

#### Classe `Result` Completa

Aqui tá a classe `Result` completa:

```java
package com.hogemann.monad;

import java.util.function.Consumer;
import java.util.function.Function;

public class Result<V> {

    private final V value;
    private final Exception error;

    private Result(V value, Exception error) {
        this.value = value;
        this.error = error;
    }

    public static <V> Result<V> ok(V value) {
        return new Result<>(value, null);
    }

    public static <V> Result<V> error(Exception error) {
        return new Result<>(null, error);
    }

    public static <V> Result<V> empty() {
        return new Result<>(null, null);
    }

    public V get() {
        return this.value;
    }

    public Exception error() {
        return this.error;
    }

    public boolean isOk() {
        return this.error == null && this.value != null;
    }

    public boolean isEmpty() {
        return this.value == null && this.error == null;
    }

    public <U> Result<U> map(Function<V, U> mapper) {
        if (isOk()) {
            return ok(mapper.apply(value));
        } else {
            return error(error);
        }
    }

    public <U> Result<U> flatMap(Function<V, Result<U>> mapper) {
        if (isOk()) {
            return mapper.apply(value);
        } else {
            return error(error);
        }
    }

    public void ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer) {
        if (isOk()) {
            consumer.accept(value);
        } else {
            errorConsumer.accept(error);
        }
    }
}
```

### Exemplos de Uso

Pra mostrar como usar o Monad `Result`, vamos ver alguns exemplos práticos.

#### Exemplo 1: Lidando com uma Operação Bem-Sucedida

Nesse exemplo, vamos simular uma operação que deu certo e retorna um `Result` contendo um valor.

```java
public class Example {
    public static void main(String[] args) {
        Result<String> successResult = Result.ok("Operação deu bom");

        successResult.ifOkOrElse(
            value -> System.out.println("Sucesso: " + value),
            error -> System.err.println("Erro: " + error.getMessage())
        );
    }
}
```

Saída:
```
Sucesso: Operação deu certo
```

#### Exemplo 2: Lidando com uma Operação com Falha

Aqui, simulamos uma operação que deu errado e retorna um `Result` contendo um erro.

```java
public class Example {
    public static void main(String[] args) {
        Result<String> errorResult = Result.error(new Exception("Operação falhou"));

        errorResult.ifOkOrElse(
            value -> System.out.println("Sucesso: " + value),
            error -> System.err.println("Erro: " + error.getMessage())
        );
    }
}
```

Saída:
```
Erro: Operação falhou
```

#### Exemplo 3: Encadeando Operações com `map`

Esse exemplo mostra como transformar o valor dentro de um `Result` usando o método `map`.

```java
public class Example {
    public static void main(String[] args) {
        Result<Integer> initialResult = Result.ok(5);

        Result<Integer> transformedResult = initialResult.map(value -> value * 2);

        transformedResult.ifOkOrElse(
            value -> System.out.println("Valor Transformado: " + value),
            error -> System.err.println("Erro: " + error.getMessage())
        );
    }
}
```

Saída:
```
Valor Transformado: 10
```

#### Exemplo 4: Encadeando Operações com `flatMap`

Nesse exemplo, a gente usa o método `flatMap` pra encadear operações que retornam instâncias de `Result`.

```java
public class Example {
    public static void main(String[] args) {
        Result<Integer> initialResult = Result.ok(5);

        Result<Integer> finalResult = initialResult.flatMap(value -> Result.ok(value * 2));

        finalResult.ifOkOrElse(
            value -> System.out.println("Valor Final: " + value),
            error -> System.err.println("Erro: " + error.getMessage())
        );
    }
}
```

Saída:
```
Valor Final: 10
```

Esses exemplos mostram como o Monad `Result` pode ser usado pra lidar com operações que podem dar certo ou errado e como encadear operações de uma maneira funcional.