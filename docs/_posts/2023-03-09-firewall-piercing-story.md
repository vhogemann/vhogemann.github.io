---
layout: post
title:  "Uma história sobre firewall piercing"
tags: portuguese
categories: hacking story
---

![Screenshot](/assets/20230306162208.png)

Em 2010/2011, a empresa onde eu trabalhava enfrentou dificuldades para se acertar com um novo cliente em seus primeiros projetos. Uma das principais complicações foi o acesso limitado a máquinas para trabalhar. O cliente havia contratado uma equipe de 20 desenvolvedores, mas só disponibilizou uma única máquina via VPN para eles usarem.

A solução para a entrega do código não era eficiente: acessar o desktop remoto compartilhando o disco local, copiar o código para a máquina remota e fazer o commit via CVS. E o pior, só uma pessoa por vez podia acessar o desktop remoto.

![Diagram](/assets/20230306161358.png)

Pedir para acessar o servidor de CVS via VPN estava fora de questão. Então, a solução encontrada foi compartilhar uma única conexão de rede entre várias máquinas. Existem diversas formas de fazer isso, mas a escolhida foi um proxy SOCKS, que é usado para fazer proxy de conexões TCP, suportando praticamente qualquer protocolo.

Para que isso fosse possível, instalamos um proxy SOCKS na máquina com acesso à VPN. Porém, isso não era suficiente, pois essa VPN só permitia acesso via RDP. A única máquina que tinha acesso ao CVS era o desktop remoto, então era preciso compartilhar a conexão dele de alguma forma. Novamente, a solução foi usar um proxy SOCKS, mas dessa vez no desktop remoto.

Mas como fazer isso? O Firewall iria bloquear qualquer conexão que não fosse RDP, ou pelo menos era o que pensamos. Usando nmap, descobrimos que o firewall não bloqueava conexões na porta 53, que é a porta usada pelo serviço DNS. Então, instalamos outro servidor SOCKS no desktop remoto na porta 53 e assim conseguimos que todo mundo pudesse acessar o repositório CVS do cliente.

![Diagram](/assets/20230306162326.png)

Um último detalhe é que o proxy SOCKS escolhido foi o JSOCKS. Ele é um proxy SOCKS escrito em Java, o que é perfeito já que não tinhamos permissão de instalar nada na máquina remota, mas ela estava configurada para desenvolvimento Java.

