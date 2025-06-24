% === Função: obter_respostas_marcadas ===
% Descrição:
%   Analisa a matriz de bolhas classificadas para cada questão e determina
%   qual alternativa foi marcada pelo aluno com base na intensidade média
%   dos pixels (em imagem binária). Utiliza um limiar para ignorar marcações ambíguas.
%
% Entradas:
%   img_bw             - imagem binária da folha de respostas (1 = bolha preenchida)
%   matriz_respostas   - matriz (Q x 5) de structs com dados das bolhas por questão
%
% Saída:
%   respostas_marcadas - vetor (Qx1) com o índice da alternativa marcada (1–5), ou 0 se nenhuma clara

function respostas_marcadas = obter_respostas_marcadas(img_bw, matriz_respostas)
    [n_questoes, n_alternativas] = size(matriz_respostas);
    respostas_marcadas = zeros(n_questoes, 1);
    limiar_diferenca = 0.085;  % Ajuste fino — sensível para folhas em branco

    figure('Name', 'Diagnóstico: Questões e Alternativas');
    imshow(img_bw); hold on;

    for i = 1:n_questoes
        alternativas = matriz_respostas(i, :);

        % Ordena horizontalmente (eixo X) para garantir A–E
        centros = reshape([alternativas.Centroid], 2, []).';
        [~, idx_x] = sort(centros(:,1));
        alternativas = alternativas(idx_x);

        intensidades = zeros(1, n_alternativas);

        for j = 1:n_alternativas
            bolha = alternativas(j);
            bbox = round(bolha.BoundingBox);
            row_start = max(1, bbox(2));
            row_end = min(size(img_bw, 1), bbox(2) + bbox(4) - 1);
            col_start = max(1, bbox(1));
            col_end = min(size(img_bw, 2), bbox(1) + bbox(3) - 1);

            if row_start <= row_end && col_start <= col_end
                sub_bolha = img_bw(row_start:row_end, col_start:col_end);
                intensidades(j) = mean(sub_bolha(:));
            end

            c = bolha.Centroid;
            text(c(1), c(2), sprintf('Q%d-%c', i, char(64+j)), ...
                'Color', 'yellow', 'FontSize', 6, 'HorizontalAlignment', 'center');
        end

        [max_valor, marcada] = max(intensidades);
        media_outros = mean(setdiff(intensidades, max_valor)); % evita auto-comparação

        if (max_valor - media_outros) > limiar_diferenca
            respostas_marcadas(i) = marcada;
            rectangle('Position', alternativas(marcada).BoundingBox, ...
                      'EdgeColor', 'g', 'LineWidth', 1.5);
        else
            respostas_marcadas(i) = 0;  % Nenhuma bolha se destacou suficientemente
        end

        centro = mean(reshape([alternativas.Centroid], 2, []), 2)';
        rectangle('Position', [min(centros(:,1)), min(centros(:,2)), ...
            max(centros(:,1)) - min(centros(:,1)), max(centros(:,2)) - min(centros(:,2))], ...
            'EdgeColor', 'cyan', 'LineWidth', 1);
        text(centro(1), centro(2), sprintf('%d', i), ...
            'Color', 'cyan', 'FontSize', 9, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    end

    title('Módulo 5: Organização das Questões e Alternativas');
    hold off;
end
