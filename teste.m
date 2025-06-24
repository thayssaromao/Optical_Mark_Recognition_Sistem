% === Arquivo: OMR.m ===
% Descrição: Sistema OMR Modularizado - MATLAB. Arquivo para teste dos
% módulos implementados.
% Autores: Matheus Araújo Akiyoshi Loureiro e Thayssa Daniele Pacheco Romão
% Curso: Processamento Digital de Imagens - UTFPR


% --- Definições das Funções (Módulos 1 a 5) ---

% Módulo 1: Leitura da imagem da folha de respostas
function img_gray = ler_folha_resposta(caminho_imagem)
    img = imread(caminho_imagem);
    if size(img,3) == 3
        img_gray = rgb2gray(img);
    else
        img_gray = img;
    end
    img_gray = im2double(img_gray);
end

% Módulo 2: Pré-processamento (binarização e morfologia)
function [bw_final, bw_sem_open] = preprocessar_imagem(img_gray)
    bw = imbinarize(img_gray);
    bw = imcomplement(bw);
    bw_sem_open = bw;
    bw = bwareaopen(bw, 30);
    bw_final = imclose(bw, strel('disk', 5));
end

% Módulo 3: Detecção das bolhas (com ajuste automático de área)
function bolhas = detectar_bolhas(bw)
    % Remoção inicial de ruído muito pequeno
    bw = bwareaopen(bw, 80);  % Reduzido de 100 para 80

    cc = bwconncomp(bw);
    props = regionprops(cc, 'Area', 'Centroid', 'BoundingBox', 'Eccentricity', 'Perimeter');

    todas_areas = [props.Area];
    if isempty(todas_areas)
        bolhas = [];
        warning('Nenhuma região conectada detectada na imagem binarizada.');
        return;
    end

    % Parâmetros dinâmicos ajustados levemente para mais flexibilidade
    p20 = prctile(todas_areas, 20);
    p90 = prctile(todas_areas, 90);
    area_min = max(400, p20 * 0.85);         % antes 500, agora 400
    area_max = min(p90 * 1.6, 3200);         % antes 1.5 e 3000
    eccentricity_max = 0.75;                 % antes 0.7
    circularity_min = 0.45;                  % antes 0.5

    is_valid = false(size(props));

    for k = 1:length(props)
        area = props(k).Area;
        ecc = props(k).Eccentricity;
        bbox = props(k).BoundingBox;
        ratio = bbox(3) / bbox(4);
        perimeter = props(k).Perimeter;
        circularity = 4 * pi * area / (perimeter^2);

        if area >= area_min && area <= area_max && ...
           ecc <= eccentricity_max && ...
           ratio > 0.5 && ratio < 2.0 && ...
           circularity > circularity_min
            is_valid(k) = true;
        end
    end

    bolhas = props(is_valid);

    % Diagnóstico
    fprintf('[Módulo 3 - Diagnóstico Final Ajustado]\n');
    fprintf('Total regiões conectadas: %d\n', length(props));
    fprintf('Bolhas válidas: %d\n', length(bolhas));
    fprintf('Área válida: %.1f a %.1f | Circularidade > %.2f\n', area_min, area_max, circularity_min);

    % Histograma
    figure('Name', 'Módulo 3 - Histograma de Áreas (Ajustado)');
    histogram(todas_areas, 50);
    xline(area_min, '--r', 'area\_min');
    xline(area_max, '--g', 'area\_max');
    title('Áreas das Regiões Conectadas');
    xlabel('Área (pixels)');
    ylabel('Frequência');
end



% Módulo 4: Classificação das bolhas por colunas (assumindo 2 colunas de 25 questões)
function matriz_respostas = classificar_bolhas(bolhas, n_questoes, n_alternativas)
    total_esperado = n_questoes * n_alternativas;
    if length(bolhas) ~= total_esperado
        error('Número de bolhas detectadas (%d) difere do esperado (%d).', length(bolhas), total_esperado);
    end

    centroids = reshape([bolhas.Centroid], 2, []).';
    [~, idx_sort_x] = sort(centroids(:,1));
    bolhas_ordenadas_x = bolhas(idx_sort_x);

    bloco1 = bolhas_ordenadas_x(1:125);
    bloco2 = bolhas_ordenadas_x(126:250);

    centroids1 = reshape([bloco1.Centroid], 2, []).';
    [~, idx1] = sort(centroids1(:,2));
    bloco1 = bloco1(idx1);

    centroids2 = reshape([bloco2.Centroid], 2, []).';
    [~, idx2] = sort(centroids2(:,2));
    bloco2 = bloco2(idx2);

    bolhas_ordenadas_final = [bloco1(:); bloco2(:)];

    % Aqui está a correção principal
    matriz_respostas = reshape(bolhas_ordenadas_final, n_alternativas, n_questoes).';
end


% Módulo 5: Verificar bolhas marcadas com ordenação interna das alternativas por X
function respostas_marcadas = obter_respostas_marcadas(img_bw, matriz_respostas)
    [n_questoes, n_alternativas] = size(matriz_respostas);
    respostas_marcadas = zeros(n_questoes, 1);

    figure('Name', 'Diagnóstico: Questões e Alternativas');
    imshow(img_bw); hold on;

    for i = 1:n_questoes
        alternativas = matriz_respostas(i, :);

        % Ordena as bolhas da questão pelo eixo X (horizontal) — garante ordem A-E
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

        [~, marcada] = max(intensidades);
        respostas_marcadas(i) = marcada;

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

% Módulo 6: Comparação com o Gabarito

gabarito = [
    1, 2, 3, 4, 5, 1, 2, 3, 4, 5, ... % Questões 1-10
    1, 2, 3, 4, 5, 1, 2, 3, 4, 5, ... 
    1, 2, 3, 4, 5, 1, 2, 3, 4, 5, ... 
    1, 2, 3, 4, 5, 1, 2, 3, 4, 5, ... 
    1, 2, 3, 4, 5, 1, 2, 3, 4, 5    ... 
];




% --- Script Principal de Execução ---
caminho_imagem_fr = 'FR.jpeg';


fprintf('Iniciando processamento OMR para a imagem: %s\n', caminho_imagem_fr);

img_gray = ler_folha_resposta(caminho_imagem_fr);
figure('Name', 'Módulo 1');
imshow(img_gray);
title('Módulo 1: Imagem Original (Grayscale)');

[bw, bw_para_marca] = preprocessar_imagem(img_gray);
figure('Name', 'Módulo 2');
imshow(bw);
title('Módulo 2: Imagem Binarizada e Morfologia');

bolhas = detectar_bolhas(bw);
fprintf('Número de bolhas detectadas: %d\n', length(bolhas));

figure('Name', 'Módulo 3');
imshow(img_gray);
title(sprintf('Módulo 3: Bolhas Detectadas (%d)', length(bolhas)));
hold on;
for k = 1 : length(bolhas)
    thisBB = bolhas(k).BoundingBox;
    rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],'EdgeColor','r','LineWidth',1.5);
end
hold off;

if ~isempty(bolhas)
   areas_detectadas = [bolhas.Area];
   fprintf('Áreas das bolhas detectadas (min/max): %.2f / %.2f\n', min(areas_detectadas), max(areas_detectadas));
   figure('Name', 'Diagnóstico: Áreas');
   histogram(areas_detectadas);
   title('Distribuição das Áreas das Bolhas Detectadas');
   xlabel('Área (pixels)');
   ylabel('Frequência');
end

total_bolhas_esperadas = 50 * 5;
if length(bolhas) ~= total_bolhas_esperadas
    warning('Número de bolhas detectadas (%d) difere do esperado (%d). Isso pode causar erro no Módulo 4.', ...
            length(bolhas), total_bolhas_esperadas);
end

try
    matriz_respostas_bolhas = classificar_bolhas(bolhas, 50, 5);
    figure('Name', 'Módulo 4');
    imshow(img_gray); hold on;
    for i = 1:size(matriz_respostas_bolhas,1)
        for j = 1:size(matriz_respostas_bolhas,2)
            c = matriz_respostas_bolhas(i,j).Centroid;
            plot(c(1), c(2), 'b.');
        end
    end
    title('Módulo 4: Bolhas Classificadas por Questão e Alternativa');
    hold off;
catch ME
    fprintf('Erro crítico no Módulo 4 (Classificação): %s\n', ME.message);
    return;
end

respostas_marcadas_aluno = obter_respostas_marcadas(bw_para_marca, matriz_respostas_bolhas);

fprintf('Tamanho de respostas do aluno: %d\n', length(respostas_marcadas_aluno));
fprintf('Respostas marcadas pelo aluno:\n');
respostas_marcadas_aluno = obter_respostas_marcadas(bw_para_marca, matriz_respostas_bolhas);

fprintf('Tamanho de respostas do aluno: %d\n', length(respostas_marcadas_aluno));
fprintf('Respostas marcadas pelo aluno:\n');
for i = 1:length(respostas_marcadas_aluno)
    fprintf('Questão %2d: Alternativa %d\n', i, respostas_marcadas_aluno(i));
end

figure('Name', 'Resumo - Módulo 5');
bar(respostas_marcadas_aluno);
ylabel('Alternativa Marcada');
xlabel('Questão');
title('Resumo: Respostas Marcadas pelo Aluno');


%%
fprintf('\n===== COMPARAÇÃO QUESTÃO A QUESTÃO =====\n');

cont = 0;
numQuestoes = 50;
for i = 1:numQuestoes
    correto = respostas_marcadas_aluno(i) == gabarito(i);
    status = "❌";
    if correto
        status = "✔️";
        cont = cont + 1;

    end
    fprintf('Q%02d: Marcada = %s | Correta = %s %s\n', i, ...
        char(64 + respostas_marcadas_aluno(i)), char(64 + gabarito(i)), status);
    
     
end

acertos = cont;
notaFinal = (acertos/numQuestoes)*100;

fprintf('\n===== RESULTADO FINAL =====\n');
fprintf('Total de acertos: %d de %d\n', acertos, numQuestoes);
fprintf('Nota final: %.2f%%\n', notaFinal);

if notaFinal >= 60
    fprintf('Situação: ✅ Aprovado!\n');
else
    fprintf('Situação: ❌ Reprovado.\n');
end