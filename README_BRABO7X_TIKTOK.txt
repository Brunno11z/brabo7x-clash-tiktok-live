BRABO7X CLASH LIVE — TikTok Interactive
========================================

O que foi adicionado
- Painel local Black OLED: http://127.0.0.1:8765
- WebSocket painel <-> jogo JavaFX
- Chave Euler + TikTokLive
- Eventos de comentário e presente
- Regras configuráveis: Time Azul/Vermelho, carta, quantidade e lado
- Modo teste sem estar em LIVE
- Presentes em sequência (streak) contam apenas a diferença para evitar duplicação
- Limite de spawn por evento para proteger desempenho
- Modo TikTok separado do modo normal do jogo
- Partida Azul x Vermelho sem gasto de elixir para eventos da LIVE
- Reinício automático de rodada quando a King Tower cai

Cartas disponíveis
Archer, Barbarian, BabyDragon, Giant, MiniPekka, Valkyrie, Wizard,
Cannon, InfernoTower, FireBall, Arrows, Rage

Como abrir
1) Instale Python 3.12.x e Java JDK 21.
   O iniciador baixa o Apache Maven 3.9.16 oficial automaticamente se necessario.
2) Para abrir tudo, execute INICIAR_TUDO_TIKTOK.bat.
   Ou abra separadamente INICIAR_PAINEL_TIKTOK.bat e INICIAR_JOGO_TIKTOK.bat.
4) No painel, primeiro use "Teste sem LIVE". O indicador JOGO precisa ficar CONECTADO.
5) Informe o @ do TikTok e, opcionalmente, a chave Euler; clique Salvar.
6) Configure presentes e comentários e clique Conectar LIVE.

Observações
- O projeto usa TikTokLive, uma integração de terceiros para receber eventos da LIVE.
- A chave Euler melhora/gerencia a conexão do TikTokLive e deve ser criada no painel Euler Stream.
- O painel roda apenas em 127.0.0.1 e não expõe porta para a rede por padrão.
- Não há automação de presentes ou interação falsa; o sistema apenas reage a eventos reais recebidos.
