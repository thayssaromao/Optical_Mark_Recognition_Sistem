% === Função: classificar_bolhas ===
% Descrição:
%   Ordena e organiza as bolhas detectadas em uma matriz de respostas de
%   dimensões [n_questoes x n_alternativas]. Assume que as bolhas estão dispostas
%   em colunas verticais e realiza ordenações com base nas coordenadas dos centróides das bolhas.
%
% Entradas:
%   bolhas         - vetor de structs com propriedades das bolhas detectadas (ex: Centroid)
%   n_questoes     - número total de questões (ex: 50)
%   n_alternativas - número de alternativas por questão (ex: 5 para A-E)
%
% Saída:
%   matriz_respostas - matriz de dimensão [n_questoes x n_alternativas], onde cada
%                      célula contém uma bolha (struct) posicionada de acordo com
%                      sua questão e alternativa correspondente
function matriz_respostas = classificar_bolhas(bolhas, n_questoes, n_alternativas)
    total_esperado = n_questoes * n_alternativas;
    
    if length(bolhas) ~= total_esperado
        error('Número de bolhas detectadas (%d) difere do esperado (%d).', length(bolhas), total_esperado);
    end

    % Extrai centróides das bolhas
    centroids = reshape([bolhas.Centroid], 2, []).';

    % Ordena bolhas pelo eixo X (esquerda para direita — para dividir em 2 blocos)
    [~, idx_sort_x] = sort(centroids(:,1));
    bolhas_ordenadas_x = bolhas(idx_sort_x);

    % Divide em dois blocos: colunas esquerda (1:25) e direita (26:50)
    bloco1 = bolhas_ordenadas_x(1:total_esperado/2);
    bloco2 = bolhas_ordenadas_x(total_esperado/2 + 1:end);

    % Ordena cada bloco por Y (cima para baixo — para alinhar por questão)
    centroids1 = reshape([bloco1.Centroid], 2, []).';
    [~, idx1] = sort(centroids1(:,2));
    bloco1 = bloco1(idx1);

    centroids2 = reshape([bloco2.Centroid], 2, []).';
    [~, idx2] = sort(centroids2(:,2));
    bloco2 = bloco2(idx2);

    % Junta novamente os dois blocos em ordem final
    bolhas_ordenadas_final = [bloco1(:); bloco2(:)];

    % Reorganiza em matriz [questões x alternativas]
    matriz_respostas = reshape(bolhas_ordenadas_final, n_alternativas, n_questoes).';
end
