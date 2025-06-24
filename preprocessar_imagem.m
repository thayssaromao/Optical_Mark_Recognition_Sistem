% Função: preprocessar_imagem
%
% Descrição:
%   Realiza o pré-processamento da imagem da folha de respostas (FR),
%   retornando diferentes binarizações e versões morfologicamente tratadas.
%   O objetivo é lidar com diferentes condições de iluminação, ruído
%   e presença de sombras na imagem, utilizando tanto caminhos leves
%   quanto robustos de segmentação.
%
% Entradas:
%   img_gray - imagem da folha de respostas em escala de cinza (double [0,1])
%
% Saídas:
%   bw_final        - imagem binária principal, resultado da morfologia leve
%   bw_r5           - imagem binária com fechamento morfológico com raio 5
%   bw_sem_open     - imagem binária inicial, sem remoção de ruído
%   bw_soft_close   - imagem com preenchimento de furos (método suave)
%   bw_ref_robusta  - imagem binária robusta para casos de sombra e baixa qualidade
function [bw_final, bw_r5, bw_sem_open, bw_soft_close, bw_ref_robusta] = preprocessar_imagem(img_gray)
    % --- Caminho leve (funciona para imagens boas) ---
    bw = imbinarize(img_gray);
    bw = imcomplement(bw);
    bw_sem_open = bw;

    bw_open = bwareaopen(bw, 30);
    bw_r5 = imclose(bw_open, strel('disk', 5));
    bw_final = imclose(bw_open, strel('disk', 6));
    bw_soft_close = imfill(bw, 'holes');

    % --- Caminho robusto para sombra: Otimizado ---
    % 1. Suavizar a imagem para melhor estimativa de fundo (menos agressivo que o anterior)
    % Pode-se até tentar remover esta linha e ver o impacto
    img_aeq_robust = adapthisteq(img_gray); % Mantém o CLAHE para contraste local
    img_suavizada = imgaussfilt(img_aeq_robust, 20); % Reduz sigma de 5 para 20, ou até mais se necessário. Pode ser removido se imopen for suficiente.

    % 2. Estimar o fundo usando abertura morfológica (geralmente mais rápido que medfilt2 para este fim)
    % O raio do disco deve ser maior que o diâmetro das bolhas para removê-las e estimar o fundo
    raio_strel = 40; % Ajuste este raio (e.g., 30, 50, 60). Metade do 80 que vc usava.
    fundo_estimado_robust = imopen(img_suavizada, strel('disk', raio_strel));

    % 3. Normalizar a imagem dividindo pelo fundo
    img_normalizada_robust = img_aeq_robust ./ (fundo_estimado_robust + 0.01);
    % Opcional: imadjust pode ser omitido se a binarização adaptativa for suficiente
    % img_normalizada_robust = imadjust(img_normalizada_robust);

    % 4. Binarizar a imagem normalizada
    bw_robusta = imbinarize(img_normalizada_robust, 'adaptive', ...
        'ForegroundPolarity', 'dark', 'Sensitivity', 0.5); % Mantenha Sensitivity para ajuste fino

    bw_robusta = imcomplement(bw_robusta); % Inverte para bolhas brancas
    bw_robusta = bwareaopen(bw_robusta, 30); % Remove pequenos ruídos
    bw_ref_robusta = imfill(bw_robusta, 'holes'); % Preenche furos

end