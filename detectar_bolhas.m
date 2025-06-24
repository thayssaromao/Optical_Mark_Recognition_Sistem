% === Função: detectar_bolhas ===
% Descrição:
%   Realiza a detecção de bolhas em uma imagem binária utilizando
%   múltiplas estratégias de fallback. Se a detecção principal não
%   retornar exatamente 250 bolhas (expectativa padrão para 50 questões
%   com 5 alternativas), tenta imagens alternativas com critérios
%   mais permissivos.
%
% Entradas:
%   bw_final        - imagem binária final (após morfologia e abertura)
%   bw_r5           - imagem com fechamento de raio 5
%   bw_soft_close   - imagem com preenchimento de buracos ('soft fallback')
%   bw_ref_robusta  - imagem com pré-processamento robusto para emergência
%
% Saída:
%   bolhas          - estrutura com propriedades das bolhas detectadas
%                     (centroides, área, bounding box etc.)
function bolhas = detectar_bolhas(bw_final, bw_r5, bw_soft_close, bw_ref_robusta)
    bolhas = detectar_com_criterios(bw_final, 'normal');
    if length(bolhas) ~= 250
        bolhas = detectar_com_criterios(bw_r5, 'normal');
    end
    if length(bolhas) ~= 250
        bolhas = detectar_com_criterios(bw_soft_close, 'fallback');
    end
    if length(bolhas) ~= 250
        bolhas = detectar_com_criterios(bw_ref_robusta, 'emergencia');
    end
end


% === Função auxiliar: detectar_com_criterios ===
% Descrição:
%   Realiza a detecção de bolhas com critérios específicos de área,
%   excentricidade, circularidade e proporção do bounding box.
function bolhas = detectar_com_criterios(bw, modo)
    switch modo
        case 'normal'
            min_area = 80;
            ecc_max = 0.75;
            circ_min = 0.45;
        case 'fallback'
            min_area = 60;
            ecc_max = 0.78;
            circ_min = 0.35;
        case 'emergencia'
            min_area = 40;
            ecc_max = 0.85;
            circ_min = 0.25;
        otherwise
            error('Modo inválido');
    end

    bw = bwareaopen(bw, min_area);
    cc = bwconncomp(bw);
    props = regionprops(cc, 'Area', 'Centroid', 'BoundingBox', 'Eccentricity', 'Perimeter');

    todas_areas = [props.Area];
    if isempty(todas_areas)
        bolhas = [];
        return;
    end

    p20 = prctile(todas_areas, 20);
    p90 = prctile(todas_areas, 90);
    area_min = max(300, p20 * 0.7);
    area_max = min(p90 * 2.0, 4000);

    is_valid = false(size(props));
    for k = 1:length(props)
        a = props(k).Area;
        ecc = props(k).Eccentricity;
        bb = props(k).BoundingBox;
        ratio = bb(3)/bb(4);
        peri = props(k).Perimeter;
        circ = 4*pi*a/(peri^2);
        if a >= area_min && a <= area_max && ...
           ecc <= ecc_max && ...
           ratio > 0.3 && ratio < 2.5 && ...
           circ > circ_min
            is_valid(k) = true;
        end
    end

    props_validas = props(is_valid);
    num_validas = length(props_validas);

    % --- Limita a 250 bolhas, se exceder ---
    if num_validas > 250
        [~, idx_area] = sort([props_validas.Area], 'descend');
        props_validas = props_validas(idx_area(1:250));
        fprintf('[Módulo 3 - %s] Reduzido para 250 bolhas mais prováveis.\n', upper(modo));
    end

    bolhas = props_validas;

    fprintf('[Módulo 3 - %s] Bolhas válidas: %d (Área %.0f–%.0f)\n', ...
        upper(modo), length(bolhas), area_min, area_max);
end

