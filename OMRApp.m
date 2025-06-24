% === Função: OMRApp ===
% Descrição: Interface gráfica principal do sistema OMR.
%            Permite carregar uma imagem de folha de respostas, carregar um gabarito
%            e executar a correção da prova exibindo o resultado.
%
% Interface:
%   - Botões de controle (Carregar Imagem, Carregar Gabarito, Corrigir Prova)
%   - Área de visualização da imagem
%   - Área de exibição do resultado (TextArea)
%
% Observações:
%   - A imagem deve estar nos formatos .jpg, .jpeg ou .png
%   - O gabarito pode estar nos formatos .txt ou .mat (com variável 'gabarito')
%
% Uso:
%   Basta chamar `OMRApp()` no MATLAB para abrir a interface.
function OMRApp()
    fig = uifigure('Name', 'Sistema Optical Mark Recognition (OMR)', 'Position', [100, 100, 900, 500]);

    imagem = [];
    gabarito = [];

    % --- PAINEL DE BOTÕES (lado esquerdo) ---
    painelBotoes = uipanel(fig, ...
        'Title', 'Controles', ...
        'Position', [20, 20, 220, 460]);

    uibutton(painelBotoes, 'push', ...
        'Text', 'Carregar Imagem', ...
        'Position', [10, 380, 200, 30], ...
        'ButtonPushedFcn', @(btn, event) carregarImagem());

    uibutton(painelBotoes, 'push', ...
        'Text', 'Carregar Gabarito', ...
        'Position', [10, 330, 200, 30], ...
        'ButtonPushedFcn', @(btn, event) carregarGabarito());

    uibutton(painelBotoes, 'push', ...
        'Text', 'Corrigir Prova', ...
        'Position', [10, 280, 200, 30], ...
        'ButtonPushedFcn', @(btn, event) corrigir());

    txtResultado = uitextarea(painelBotoes, ...
        'Position', [10, 20, 200, 240], ...
        'Editable', 'off', ...
        'FontSize', 12, ...
        'Value', {'Resultado aparecerá aqui...'});

    % --- ÁREA DA IMAGEM (lado direito) ---
    ax = uiaxes(fig, ...
        'Position', [260, 20, 620, 460]);
    axis(ax, 'off');

    % --- Funções internas ---

    function carregarImagem()
        [file, path] = uigetfile({'*.jpg;*.png;*.jpeg'}, 'Selecione a folha');
        if isequal(file, 0), return; end
        caminho = fullfile(path, file);
        imagem = imread(caminho);
        imshow(imagem, 'Parent', ax);
        title(ax, sprintf('Imagem Carregada: %s', file));

    end

    function carregarGabarito()
        [file, path] = uigetfile({'*.txt'}, 'Selecione o gabarito');
        if isequal(file, 0), return; end
        caminho = fullfile(path, file);
        [~, ~, ext] = fileparts(caminho);

        if strcmp(ext, '.mat')
            dados = load(caminho);
            if isfield(dados, 'gabarito')
                gabarito = dados.gabarito;
                
            else
                uialert(fig, 'Variável "gabarito" não encontrada.', 'Erro');
            end
        elseif strcmp(ext, '.txt')
            gabarito = load(caminho);
           
        else
            uialert(fig, 'Formato inválido.', 'Erro');
        end
        txtResultado.Value = {
        sprintf('✅ Gabarito carregado com sucesso!');
        sprintf('Total de questões: %d', numel(gabarito))
    };
    end

    txtResultado.Value = {''};
    function corrigir()
        if isempty(imagem)
            uialert(fig, 'Imagem não carregada.', 'Erro'); return;
        end
        if isempty(gabarito)
            uialert(fig, 'Gabarito não carregado.', 'Erro'); return;
        end

        try
            txtResultado.Value = {'⏳ Corrigindo... aguarde.'};
            drawnow;
            txtResultado.Value = {''};
            [notaFinal, acertos, respostas_marcadas_aluno] = executarPipelineOMR(imagem, gabarito, ax);
            exibirResultado(respostas_marcadas_aluno,gabarito, txtResultado)
        catch ME
            uialert(fig, ['Erro: ' ME.message], 'Erro');
        end
    end
end
