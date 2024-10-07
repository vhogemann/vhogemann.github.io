---
layout: post
title:  "Integrando cache ao Spring com EHCache"
tags: portuguese java spring ehcache
image: /assets/spring-cache.png
---

> Esse é um artigo que eu escrevi em 2011, algumas coisas já estão desatualizadas,
> mas o conteúdo ainda pode ser útil.

![Spring com EHCache](/assets/spring-cache.png)

# Integrando cache ao Spring

**Um módulo que facilita a tarefa de implementar caching de métodos, de uma forma praticamente transparente.**

Caches são uma técnica comum para resolver problemas de performance. A ideia por trás é guardar informações para que possam ser reutilizadas, ao invés de arcar com os custos de gerar os dados novamente.

Eles são tão difundidos que podemos os encontrar em praticamente todos os níveis de um sistema, desde o processador, passando pelo sistema operacional, aplicações e entre diversas máquinas interconectadas em uma rede.

É natural então que encontremos implementações de cache para o Java, desde as mais simples até soluções que distribuem gigabytes de dados entre várias máquinas diferentes. Nesse artigo vamos tratar de uma solução em especial, que se integra ao SpringFramework e é bem fácil de ser aplicada na grande maioria dos projetos que o utilizam. 

**EHCache Spring Annotations**  
Essa é a solução que é apresentada aqui, um projeto open-source que visa simplificar a aplicação e o uso do cache através do uso de anotações. É o sucessor de outro projeto, o Spring-Cache Module, que foi descontinuado, e não tem mais desenvolvimento ativo.

**Spring Framework**  
Mais que um conjunto de bibliotecas, oferece um conjunto integrado completo de soluções para o desenvolvimento Java. O Spring oferece diversos módulos que facilitam a integração de praticamente todas as tecnologias utilizadas no desenvolvimento J2EE. Também é um projeto open-source, e tem uma grande comunidade de desenvolvedores e usuários ao seu redor.

O EHCache Spring Annotations é uma extensão do Spring, e depende dele para ser utilizado.  

**EHCache**  
É uma implementação open-source de cache em Java, popular e amplamente utilizada é a base para a JSR-107 que visa definir uma API comum de cache para a linguagem. A simplicidade e facilidade de utilização contribuiram para sua popularidade.

*O EHCache pode ser utilizado de diversas maneiras, por exemplo ele pode fazer caching das requisições enviadas a uma aplicação Web, já enviando a resposta utilizando compressão gzip. Praticamente como implementar um proxy reverso direto na sua aplicação. Para essa e outras utilizações, visite a página do projeto, veja o link ao final do artigo.*

**Configuração**  
O primeiro passo é fazer o download da última versão do EHCache Spring Annotations a partir do site, e incluir o jar e suas dependências no classpath. Faça o download no link abaixo:

http://code.google.com/p/ehcache-spring-annotations/downloads/list

Após isso precisamos do EHCache, portanto faça o download da distribuição a partir do site oficial. Vamos utilizar a versão 1.2.4 do **ehcache.jar**.

http://www.terracotta.org/dl/ehcache-oss-download-catalog

Nos meus projetos prefiro deixar a cargo do Maven a tarefa de baixar e resolver as dependências das bibliotecas que utilizo. O Maven é uma ferramenta completa, que pode gerênciar todo ciclo de vida do seu projeto, do desenvolvimento ao deploy, passando por execução de testes e build do projeto. A **listagem 1** mostra o trecho que deve ser incluído ao arquivo de configuração do projeto, pom.xml.

**Listagem 1**. Configuração do ehcache e ehcache-spring-annotations para o maven

```xml
<pom>	
	...
<dependencies>
	... 
	<dependency>  
		<groupId>com.googlecode.ehcache-spring-annotations</groupId>  
		<artifactId>ehcache-spring-annotations</artifactId>  
		<version>1.1.3</version>  
	</dependency>  
	<dependency>  
			<groupId>net.sf.ehcache</groupId>  
			<artifactId>ehcache</artifactId>  
			<version>1.2.4</version>  
			<type>jar</type>  
			<scope>compile</scope>  
	</dependency>
	...
</dependencies>
	...
</pom>
```

Após isso é necessário criar um arquivo para configurar os caches do EHCache, qué chamado **ehcache.xml** e deve ser colocado no classpath da aplicação. A **listagem 2** mostra um arquivo com uma configuração mínima, note que podemos configurar vários caches cada um com características diferentes. Cada caso de utilização requer uma configuração específica, para efeito de exemplo configuraremos um cache apenas em memória:

**Listagem 2**. O arquivo ehcache.xml

```xml
	<ehcache>

		<cache name="books"  
			maxBytesOnHeap="50m"  
			maxBytesOffHeap="200m"  
			timeToLiveSeconds="100"  
			overflowToDisk="false" >  
		</cache>

	</ehcache>
```

Com o EHCache configurado, precisamos agora declarar no contexto Spring da sua aplicação as configurações do ehcache-spring-annotations. Veja na **listagem 3** como é simples.

**listagem 3**. Configuração do contexto do Spring, normalmente o applicationContext.xml

```xml
	<beans xmlns="http://www.springframework.org/schema/beans"  
	     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
	     xmlns:ehcache="http://ehcache-spring-annotations.googlecode.com/svn/schema/ehcache-spring"  
	     xsi:schemaLocation="  
	     http://www.springframework.org/schema/beans   
	     http://www.springframework.org/schema/beans/spring-beans-3.0.xsd  
	     http://ehcache-spring-annotations.googlecode.com/svn/schema/ehcache-spring  
	     http://ehcache-spring-annotations.googlecode.com/svn/schema/ehcache-spring/ehcache-spring-1.1.xsd">

	    <ehcache:annotation-driven />  
	    <bean id="cacheManager" class="org.springframework.cache.ehcache.EhCacheManagerFactoryBean"/>

					...

	</beans>
```

*Existem várias maneiras de configurar os caches no EHCache, existe por exemplo a possibilidade de persistir os objetos do cache em disco, ou então podemos configurar um cache distribuído utilizando o Terracota.*

**Utilizando o Cache**  
O funcionamento básico do Ehcache Annotations é interceptar a chamada aos métodos anotados, fazer cache do objeto retornado e utilizar os parâmetros, o tipo do retorno e o nome do método para gerar a chave. Os métodos são interceptados utilizando a implementação de AOP do Spring, podemos anotar os métodos diretamente na Interface, ou então nas Classes que as implementam.

Para marcar métodos para terem seu retorno adicionado ao cache, utilizamos a anotação **@Cacheable**, que recebe um parâmetro **cacheName** correspondente ao cache declarado no arquivo ehcache.xml da **listagem 2**.

Na **listagem 4** temos dois métodos anotados com **@TriggersRemove**, essa anotação indica que  quando o método for invocado devemos remover uma, ou todas, das entradas do cache. De outra forma a única maneira dos objetos serem atualizados seria o tempo de expiração configurado no EHCache, o que quase sempre não é o comportamento esperado. Por exemplo, método **updateAll** na listagem faz com que todo o cache seja invalidado quando atualizamos uma lista de objetos.

**Listagem 4**. Uma interface anotada com @Cacheable

```java
	import com.googlecode.ehcache.annotations.Cacheable;  
	import com.googlecode.ehcache.annotations.TriggersRemove;  
	import com.googlecode.ehcache.annotations.PartialCacheKey;  
	  
	public interface BookManager {

	    @Cacheable(cacheName="books",  
						keyGenerator = @KeyGenerator (  
                name = "HashCodeCacheKeyGenerator",  
                properties = @Property( name="includeMethod", value="false" )  
            )  
       )  
	    public Book load(long bookId);

				@TriggersRemove(cacheName="books",  
						keyGenerator = @KeyGenerator (  
             name = "HashCodeCacheKeyGenerator",  
             properties = @Property( name="includeMethod", value="false" )  
          )  
       )  
				public void delete(long bookId);

	    @TriggersRemove(cacheName="books",  
						keyGenerator = @KeyGenerator (  
                name = "HashCodeCacheKeyGenerator",  
                properties = @Property( name="includeMethod", value="false" )  
            )  
       )  
	    public void update( @PartialCacheKey long bookId, Book book);

	    @TriggersRemove(cacheName="books", removeAll=true)  
	    public void updateAll(List<Book> book);

	}
```

Ambas anotações, **@Cacheable** e **@TriggersRemove**, podem receber como parâmetro uma terceira anotação **@KeyGenerator**. Isso configura a estratégia de geração das chaves do cache, e é importante por um motivo: fazer **@Cacheable** e **@TriggersRemove** trabalharem em conjunto.

Como por padrão a geração das chaves do cache leva em conta o nome e o tipo de retorno do método. Os métodos **load** e **delete** da **listagem 4** acabam gerando chaves diferentes, mesmo possuindo a mesma assinatura. O comportamento desejado nesse caso é que quando o método **delete** for chamado ele utilize o parâmetro **bookId** para gerar a chave do cache, dessa forma referenciando o mesmo objeto. Assim os objetos inseridos no cache por **load** serão invalidados toda vez que houver uma chamada a **delete**.

Notem a anotação **@Properties** que define **includeMethod** como **false**. É isso que faz as chaves geradas considerarem apenas os parâmetros passados. Dessa forma as chaves geradas pela invocação de **load** e **delete** serão iguais para os mesmos valores passados.

Finalmente temos **@PartialCacheKey**, que permite que apenas alguns parâmetros da assinatura de um método sejam utilizados na criação da chave do cache. No caso do método **update** no exemplo anotamos o parâmetro **bookId** para que as chaves geradas sejam as mesmas de **load** e **delete**. Assim quando chamado, ele irá invalidar a entrada correspondente no cache, e da próxima vez que recuperarmos um objeto utilizando o método **load** ele irá pular o cache, e buscar o objeto atualizado.

**Alguns cuidados**  
> **“A otimização prematura é a raiz de todos os males”** 
> 	-- Donald Knuth, *Computer Programming as an Art*

A pesar de ser um recurso muito valioso para resolver problemas de performance, a utilização do cache deve ser estudada de maneira cuidadosa. No mundo ideal sua aplicação deveria funcionar a contento sem precisar recorrer a nenhum tipo de cache, portanto comece o projeto com esse objetivo. Não espere que utilização de caches seja uma bala-de-prata que irá resolver todos os seus problemas. Muitas vezes o cache só vai mascarar o problema, como uma consulta mal escrita no banco de dados, ou um problema de rede que torna a chamada a um WebService muito lenta.

Portanto, na maioria dos casos, o cache deve ser a última coisa a ser implementada no projeto,  quando tudo mais já funciona, e outras soluções de otimização foram aplicadas.

Caso planeje utilizar cache em disco, ou cache distribuído, certifique-se de que os objetos colocados em cache implementem a interface **Serializable**. Caso contrário eles serão descartados, e uma mensagem de alerta será enviada para o log. Outra recomendação é implementar métodos **equals** e **hashCode** para suas classes.

Se você opera num ambiente distribuido tenha em mente que por padrão o cache é local, e que isso vai fazer que as informações a respeito de um mesmo recurso possa variar nos diversos caches de cada uma das instâncias da sua aplicação. 

***Nada vem de graça: o custo do cache***  
Os caches aceleram a execução e o acesso aos recursos utilizados por sua aplicação, mas o custo disso é memória. Quanto mais informações no cache, mas memória será utilizada.

A memória disponível para sua aplicação é limitada pelo parâmetro **\-Xmx** da JVM, que configura o máximo de HEAP que poderá ser alocado. Quando utilizamos uma JVM 64bit esse limite é alto o suficiente para que em termos práticos você possa alocar toda memória disponível, ou quase toda, para sua aplicação. Mas no caso de uma JVM 32bit o limite máximo é de 2GB.

Então ao configurar seus caches, tenha em mente esses limites.

Mesmo que memória não seja um problema, definir um cache gigantesco pode não ser uma boa ideia. O importante aqui não é saber **quantos** objetos colocar em cache, mas sim saber **quais**. Informações que são alteradas muito pouco, ou nunca, e são lidas várias vezes são os candidatos ideais para irem para o cache, ao contrário de informações que são alteradas constantemente.

Além disso tudo, a má utilização do cache pode ter um impacto negativo na performance da sua aplicação. Conforme o uso de memória aumenta, também aumenta o tempo gasto pelo **Garbage Collector** da JVM, e quando a quantidade de memória alocada chega aos Gigabytes as interrupções feitas para GC começam a ser perceptíveis.

Por isso, como toda otimização o uso de cache requer planejamento e um bom entendimento do problema a ser resolvido.

**Conclusão**  
O EHCache Spring Annotations é uma solução que se encaixa bem tanto para novos projetos, quanto para projetos já existentes que utilizem o SpringFramework. A necessidade de se adaptar o código é mínima, quando necessária.

Isso o torna uma adição valiosa ao conjunto de ferramentas a sua disposição na hora em que for necessário tirar aquele “pouquinho a mais” da sua aplicação, seja para melhorar sua performance ou seja para escalar a aplicação a um número maior de usuários.

**Links**  
***http://code.google.com/p/ehcache-spring-annotations***  
EHCache Spring Annotations  
***http://ehcache.org***  
EHCache  
***http://springsource.org***  
SpringFramework  
***http://terracotta.org***  
Terracotta, desenvolvedores do EHCache.