---
layout: post
title:  "Hospedando um bot para BlueSky no Google Cloud Run"
tags: portuguese gcp cloud-run docker
categories: hosting gcp cloud-run docker
image: /assets/hosting-gcp-cloud-run.png
---

![Hospedando um bot para BlueSky no Google Cloud Run](/assets/hosting-gcp-cloud-run.png)

Encontrar um lugar pra hospedar meus projetos pessoais muitas vezes é um desafio maior que o próprio projeto em si. Principalmente porque eu não quero gastar dinheiro com isso, então compartilho aqui a solução que eu encontrei e que me atende bem.

Mas primeiro deixa eu explicar o problema que eu preciso resolver, eu tenho um [bot](https://github.com/vhogemann/rss2bsky) que faz o seguinte:

- Lê uma lista de feeds RSS
- Pra cada feed na lista, lê o XML e extrai os itens
- Compara com uma lista de items já publicados
- Publica no BlueSky os todos os itens novos
- Atualiza a lista de items publicados

Então eu preciso de duas coisas:

- Um lugar pra rodar o bot
- Um lugar pra salvar a configuração e a lista de items publicados

## O Plano

O [Cloud Run](https://cloud.google.com/run/docs/overview/what-is-cloud-run) é uma solução serverless, tem várias funcionalidades mas as importantes pra mim são:

- Fácil de configurar
- Roda um arquivo Docker com um mínimo de configuração
- Tem um [free tier](https://cloud.google.com/run/pricing)
- Eu posso montar um bucket do [Cloud Storage](https://cloud.google.com/storage/) como volume da imagem Docker

Deixando bem claro que eu estou longe de ser especialista em infra, cloud ou qualquer coisa parecida. O maior mérito do Google Cloud foi ser o que eu consegui fazer funcionar primeiro!

## O Bot

Pra se encaixar no que o Cloud Run oferece o que eu fiz foi:

- Ter um repositorio no GitHub
- Rodar no Docker
- O bot roda em batches de hora em hora
- Configuração é um arquivo JSON
- A lista de posts de cada feed é um arquivo [NDJSON](https://en.wikipedia.org/wiki/JSON_streaming)

O custo do Cloud Storage é muito menor do que subir um banco dedicado e arquivos JSON são mais do que suficientes pro que o Bot faz. Eu cheguei a pensar em usar um banco SQLite, mas seria overkill e eu imagino que rodar SQLite em um bucket do Cloud Storage não é uma idéia muito boa (mas eu ainda pretendo tentar no futuro).

## Docker

Eu estou usando um arquivo Docker em dois estágios, um pra fazer build da aplicação e o outro só com o arquivo `jar` pra ser executado. O importante aqui é que eu defino um volume em `/root/dev/json` que é onde os arquivos do bot vão estar.

Minha aplicação é em Java, mas o mesmo princípio se aplica pra qualquer outra linguagem.

```Docker
FROM eclipse-temurin:21 AS build_image
ENV APP_HOME=/root/dev/
RUN mkdir -p $APP_HOME/src/main/java
WORKDIR $APP_HOME
COPY app/build.gradle settings.gradle gradlew gradlew.bat $APP_HOME
COPY gradle $APP_HOME/gradle
# download dependencies
RUN ./gradlew build -x test --continue
COPY . .
RUN ./gradlew build

FROM eclipse-temurin:21-jre
WORKDIR /root/
COPY --from=build_image /root/dev/app/build/libs/app.jar .
RUN mkdir -p /root/dev/json

# Set environment variables
ENV JSON_PATH=/root/dev/json

# Use this to have access to the json files
VOLUME /root/dev/json

CMD ["java","-jar","app.jar"]
```

O arquivo de configuração é `source.json` e tem esse formato:
```json
[
  {
    "feedId": "example_feed",
    "name": "Example Feed",
    "rssUrl": "https://www.youtube.com/feeds/videos.xml?playlist_id=PLAYLIST_ID",
    "feedExtractor": "YOUTUBE",
    "bskyIdentity": "example.bsky.app",
    "bskyPassword": "example-app-password"
  }
]
```

E a lista de itens publicados tem o nome `{feedId}.ndjson` e o formato é apenas um bando de json separados por newline.
```json
{"sourceId":"example_feed","title":"Some title 1","url":"https://www.youtube.com/watch?v=w5ebcowAJD8"}
{"sourceId":"example_feed","title":"Some title 2","url":"https://www.youtube.com/watch?v=UE-k4hYHIDE"}
```

## Cloud Run

No Google Cloud o que você precisa criar então é:

- Um build no Cloud Build pra sua imagem Docker
- O bucket no Cloud Storage pra salvar os arquivos
- E no Cloud Run você cria um novo Job

### Build

O primeiro passo é conectar o Cloud Build com seu repo no GitHub. É só clicar em `Connect Repository` e seguir os passos.

No final é só escolher como tipo de build `Dockerfile` e o arquivo `Dockerfile` que você quer usar.

![Cloud Build](/assets/hosting-gcp-cloud-run/cloud-build.png)

### Bucket

Provavelmente a parte mais fácil, você já vai ter o Cloud Storage habilitado por causa do passo anterior (é pra onde suas imagens Docker vão).

Pra mim bastou:
- Criar um novo bucket privado
- Subir meu arquivo de configuração `source.json` pra lá

![Cloud Storage Bucket](/assets/hosting-gcp-cloud-run/cloud-storage-bucket.png)

### Job

Job é o nome que o Cloud Run dá pra um processo que roda uma vez e termina. Você cria um novo Job, escolhe a imagem docker que você criou, e configura o volume para montar o bucket do Cloud Storage.

Eu escolhi o menor tamanho possível de VM, na região mais barata que consegui encontrar. Isso significa:

- 512MiB de RAM
- 1 vCPU

![Cloud Run Job](/assets/hosting-gcp-cloud-run/cloud-run-job.png)


#### Trigger

Com o Job criado você já pode executa-lo manualmente, mas pra fazer ele rodar periodicamente é preciso criar um Trigger.

Pro meu bot eu configurei ele pra rodar de hora-em-hora, das 9h até as 18h, de Segunda até Sábado. Você faz isso usando a [sintaxe](https://en.wikipedia.org/wiki/Cron) do `cron`:

```
0 9-18 * * 1-6
```

![Cloud Run Trigger](/assets/hosting-gcp-cloud-run/cloud-run-trigger.png)

E é isso, o Job vai executar no intervalo configurado, e os arquivos vão ser lidos e salvos no bucket.

## Algumas considerações, e custos

Vale a pena ressaltar que essa solução funciona pra mim devido as características do aplicativo que eu estou rodando:

- Não é interativo, pode rodar em batches
- Acessa muito pouco o disco, cada feed atualiza mais ou menos uma vez por dia com um ou dois posts novos
- Tudo que eu preciso em termos de lógica está dentro de uma única imagem Docker

Sabendo disso tudo, o custo mensal previsto dessa brincadeira são exorbitantes `€0.10`. Então se o que você quer fazer cabe dentro das mesmas limitações que eu me impuz, eu acho que vale a pena dar o Google Cloud uma chance.

![Cloud Billing](/assets/hosting-gcp-cloud-run/cloud-billing.png)

Eu uso o bot pra alimentar várias contas que republicam vídeos dos meus canais favoritos de ciência no YouTube. Você pode conferir nessa lista do BlueSky:

- [Science Robots](https://bsky.app/profile/victor.hogemann.com/lists/3l5k4tq4ao623)

E o código fonte no meu GitHub:

- [rss2bsky](https://github.com/vhogemann/rss2bsky/)