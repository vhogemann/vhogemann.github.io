---
layout: post
title:  "Uma história sobre firewall piercing"
tags: portuguese
categories: hacking story
---

![Screenshot](/assets/20230306162208.png)

Algumas vezes você se vê obrigado a trapacear pra conseguir fazer seu trabalho. Por volta de 2010/2011 a empresa onde eu trabalhava conseguiu um contrato com um novo cliente, e tivemos algumas dificuldades em nos acertar com eles nos primeiros projetos.

Um dos primeiros problemas que nós tivemos foi em relação a máquinas pra trabalhar, eles contrataram uma equipe de 20 desenvolvedores no nosso lado, o como o ambiente deles era muito “particular” a ideia era a gente usar desktops deles via VPN por RDP. Só que eles não tinham máquinas suficientes, na realidade eles só tinham uma pra gente usar. Sim, uma máquina pra 20 desenvolvedores.

Rapidamente convencemos eles que seria uma ideia muito melhor nos deixar usar nossas próprias máquinas, e depois de uma semana de muito sangue, suor e lágrimas conseguimos fazer o build do sistema deles funcionar. Só restava um problema, entregar o código.

Tudo que nós tínhamos era o acesso a UM único desktop por Remote Desktop. Inicialmente pra entregar o código, o que nós tínhamos que fazer era:

-	Acessar o desktop remoto, por RDP, compartilhando nosso disco local
-	Copiar o código pra máquina remota
-	Fazer o commit via CVS

![Diagram](/assets/20230306161358.png)

Não é exatamente uma forma eficiente de fazer as coisas, e já seria ruim o bastante se não fosse um detalhe: só uma pessoa podia acessar o desktop remoto por vez! E como eu já disse, nós éramos cerca de 20 pessoas.

A solução óbvia seria pedir para que eles permitissem o acesso ao servidor de CVS via VPN. Mas isso definitivamente não iria acontecer, então foi preciso encontrar uma solução mais _criativa_.

Uma solução criativa
---
O que nós precisávamos fazer estava claro: compartilhar uma única conexão de rede entre várias máquinas. Existem algumas formas de fazer isso, mas nós acabamos por escolher uma que talvez não fosse a mais intuitiva: usar um proxy SOCKS.

Existem diversos tipos de proxy, o mais comum é o proxy HTTP, que é usado pra fazer cache de páginas web. Mas o tipo que nós precisávamos era o proxy SOCKS, que é usado pra fazer proxy de conexões TCP, então suporta praticamente qualquer protocolo.

Então o primeiro passo foi instalar um proxy SOCKS na máquina que tinha acesso a VPN. Mas só isso não seria suficiente, já que essa VPN só permitia acesso via RDP.

![Diagram](/assets/20230306162326.png)

Firewall Piercing
---

A única máquina que tinha acesso ao CVS era o desktop remoto, então seria preciso compartilhar a conexão dele de alguma forma. A solução novamente foi usar um proxy SOCKS, mas dessa vez no desktop remoto.

Mas como fazer isso? O Firewall iria bloquear qualquer conexão que não fosse RDP, ou pelo menos era o que nós pensávamos. Usando [nmap](https://nmap.org/) nós descobrimos que o firewall não bloqueava conexões na porta 53, que é a porta usada pelo serviço DNS.

Sim, DNS.

No final nós ficamos com um servidor SOCKS rodando na máquina com acesso a VPN, e outro servidor SOCKS rodando no desktop remoto na porta 53. Um servidor fazia _chainning_ com o outro, e assim nós conseguimos que todo mundo conseguisse acessar o repositório CVS deles.

Um último detalhe é que o proxy SOCKS que nós usamos era o [JSOCKS](https://jsocks.sourceforge.net/). Ele é um proxy SOCKS escrito em Java, o que é perfeito já que nós não tínhamos permissão de instalar nada na máquina remota, mas ela estava configurada pra desenvolvimento Java.