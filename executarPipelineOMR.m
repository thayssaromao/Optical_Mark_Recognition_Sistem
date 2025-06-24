% Função: executarPipelineOMR
% Descrição: Executa o pipeline completo do sistema OMR, incluindo pré-processamento,
%            detecção e classificação de bolhas, extração de respostas e cálculo da nota
% Entrada:
%   imagemRGB       - imagem RGB da folha de respostas do aluno
%   gabarito        - vetor com o gabarito oficial
%   ax              - objeto do tipo axes usado para exibir a imagem corrigida
% Saída:
%   nota_final      - nota total cálculo de porcentagem
%   acertos         - número total de acertos do aluno
%   respostas       - vetor contendo as respostas marcadas detectadas na folha

function [notaFinal, acertos, respostas] = executarPipelineOMR(imagemRGB, gabarito, ax)
    % Converte para escala de cinza se necessário
    if size(imagemRGB, 3) == 3
        img_gray = rgb2gray(imagemRGB);
    else
        img_gray = imagemRGB;
    end
    img_gray = im2double(img_gray);

    % Pré-processamento
    [bw_final, bw_r5, bw_para_marca, bw_soft_close, bw_ref_robusta] = preprocessar_imagem(img_gray);
    bolhas = detectar_bolhas(bw_final, bw_r5, bw_soft_close, bw_ref_robusta);


    % Visualização das bolhas detectadas (Módulo 3)
    figure('Name', 'Módulo 3: Bolhas Detectadas');
    imshow(img_gray); hold on;
    title(sprintf('Módulo 3: Bolhas Detectadas (%d)', length(bolhas)));
    for k = 1:length(bolhas)
        rectangle('Position', bolhas(k).BoundingBox, 'EdgeColor', 'r', 'LineWidth', 1.5);
    end
    hold off;
    % Classificação das bolhas
    matriz = classificar_bolhas(bolhas, 50, 5);

    % Obtenção das respostas marcadas
    respostas = obter_respostas_marcadas(bw_para_marca, matriz);

    % Cálculo da nota
    acertos = sum(respostas == gabarito(:));
    notaFinal = (acertos / numel(gabarito)) * 100;

    % Exibição final
    imshow(imagemRGB, 'Parent', ax);
    title(ax, sprintf('Corrigido: %.2f%%', notaFinal));
end




