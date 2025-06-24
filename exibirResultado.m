% Função: exibirResultado
% Descrição: Compara as respostas do aluno com o gabarito e calcula a nota final.
% Entrada:
%   respostas_aluno - vetor com respostas do aluno
%   gabarito        - vetor com o gabarito oficial
%   txtResultado    - argumento de atualização de texto de saída
% Saída:
%   nota_final      - nota total cálculo de porcentagem

function exibirResultado(respostas_marcadas_aluno, gabarito, txtResultado)
    numQuestoes = length(gabarito);
    cont = 0;
    
    linhas = strings(numQuestoes,1); 
    
    for i = 1:numQuestoes
        marcada = respostas_marcadas_aluno(i);
        correta = gabarito(i);

        if marcada == 0
            simbolo = '[SEM RESPOSTA]';
            status = "❌";
        else
            simbolo = char(64 + marcada);  % transforma 1–5 em A–E
            if marcada == correta
                status = "✔️";
                cont = cont + 1;
            else
                status = "❌";
            end
        end
        
        linhaAtual = sprintf('Q%02d: Marcada = %s | Correta = %s %s', ...
            i, simbolo, char(64 + correta), status);
        linhas(i) = linhaAtual;
    end
    
    acertos = cont;
    notaFinal = (acertos / numQuestoes) * 100;
    
    if notaFinal >= 60
        situacao = "✅ Aprovado";
    else
        situacao = "❌ Reprovado";
    end
    
    txtResultado.Value = [linhas; ""; ...
    sprintf('Nota final: %.2f%% (%d/%d acertos)', notaFinal, acertos, numQuestoes); ...
    situacao];
end
