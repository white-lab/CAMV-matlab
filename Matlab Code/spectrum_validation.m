
function spectrum_validation(varargin)
clc
close all

import javax.swing.*;
import javax.swing.tree.*;

global base_dir;
global RAW_filename;
global RAW_path;
global XML_filename;
global XML_path;
global OUT_path;
global filename;
global SL_path;
global SL_filename;
global msconvert_full_path;
global images_dir;
global data;
global mtree;
global jtree;
global prev_node;
global iTRAQType;
global iTRAQ_masses;
global iTRAQ_labels;
global SILAC;
global SILAC_R6;
global SILAC_R10;
global SILAC_K6;
global SILAC_K8;
global CID_tol;
global HCD_tol;
global accept_list;
global maybe_list;
global reject_list;
global new_accept_list;
global new_maybe_list;
global cont_thresh;
global cont_window;
global b_names_keep;
global y_names_keep;
global iTRAQ_4_plex_masses;
global iTRAQ_4_plex_labels;
global TMT_6_plex_masses;
global TMT_6_plex_labels;
global iTRAQ_8_plex_masses;
global iTRAQ_8_plex_labels;
global TMT_10_plex_masses;
global TMT_10_plex_labels;

global max_num_peaks;

global h;
global handle1;
global handle2;
global handle3;
global handle_RR;
global handle_export;
global handle_reset;
global handle_process_anyway;
global handle_search;
global handle_transfer;
global handle_file;
global handle_file_continue;
global handle_file_save;
global handle_batch_process;
global ax0;
global handle_print_now;
global handle_print_code_now;
global ax1;
global ax1_assign;
global ax1_info;
global ax2;
global ax3;
global zoom_is_clicked;
global start_zoom;
global hold_zoom_start;
global hold_zoom_end;
global is_zoomed;
global handle_prec_cont;
global handle_threshold;
global handle_window;
global handle_percent_text;
global handle_mz_text;
global handle_CID_tol;
global handle_CID_text;
global handle_HCD_tol;
global handle_HCD_text;
global handle_msconvert;


    %% Split a full file path into its filename and directory paths
    function [fname, path] = split_path(full_path)
        if ~full_path
            fname = '';
            path = '';
        else
            [path, fname, ext] = fileparts(full_path);
            fname = [fname, ext];
            path = [path '\'];
        end
    end

    %%% Handle any command line arguments
    %%% Note that all file paths must be absolute.
    function success = handle_arguments()
        success = true;
        
        p = inputParser;
        addParameter(p, 'raw_path', '');
        addParameter(p, 'xml_path', '');
        addParameter(p, 'out_path', '');
        addParameter(p, 'sl_path', '');
        addParameter(p, 'session_path', '');
        addParameter(p, 'import', false);
        addParameter(p, 'load', false);
        addParameter(p, 'save', false);
        addParameter(p, 'export', false);
        addParameter(p, 'spectra', false);
        addParameter(p, 'exit', false);
        
        parse(p, varargin{:});
        inputs = p.Results;
        
        if ischar(inputs.import)
            inputs.import = strcmp(inputs.import, 'true');
        end
        if ischar(inputs.load)
            inputs.load = strcmp(inputs.load, 'true');
        end
        if ischar(inputs.save)
            inputs.save = strcmp(inputs.save, 'true');
        end
        if ischar(inputs.export)
            inputs.export = strcmp(inputs.export, 'true');
        end
        if ischar(inputs.spectra)
            inputs.spectra = strcmp(inputs.spectra, 'true');
        end
        if ischar(inputs.exit)
            inputs.exit = strcmp(inputs.exit, 'true');
        end

        if inputs.import
            if isempty(inputs.raw_path)
                msgbox('No raw path specified.', 'Warning');
                success = false;
            end
            if isempty(inputs.xml_path)
                msgbox('No xml path specified.', 'Warning');
                success = false;
            end
            if isempty(inputs.out_path)
                msgbox('No output path specified.', 'Warning');
                success = false;
            end
            
            if ~exist(inputs.raw_path, 'file')
                msgbox('RAW input file not found.', 'Warning');
                success = false;
            end
            if ~exist(inputs.xml_path, 'file')
                msgbox('XML input file not found.', 'Warning');
                success = false;
            end
            if ~isempty(inputs.sl_path) && ~exist(inputs.sl_path, 'file')
                msgbox('Scan List input file not found.', 'Warning');
                success = false;
            end
            
            if ~success
                return;
            end
            
            [RAW_filename, RAW_path] = split_path(inputs.raw_path);
            [XML_filename, XML_path] = split_path(inputs.xml_path);
            OUT_path = inputs.out_path;
            [SL_filename, SL_path] = split_path(inputs.sl_path);
            
            process;
        end

        if inputs.load
            if isempty(inputs.session_path)
                msgbox('No session path', 'Warning');
                success = false;
                return;
            end
            
            [LOAD_filename, LOAD_path] = split_path(inputs.session_path);
            run_load_session(LOAD_filename, LOAD_path);
        end

        if inputs.save
            if isempty(inputs.session_path)
                msgbox('No session path', 'Warning');
                success = false;
                return;
            end
            
            if isempty(data)
                msgbox('No data imported or loaded');
                success = false;
                return;
            end
            
            [SAVE_filename, SAVE_path] = split_path(inputs.session_path);
            run_save_session(SAVE_filename, SAVE_path);
        end

        if inputs.export
            if isempty(data)
                msgbox('No data imported or loaded', 'Warning');
                success = false;
                return;
            end
            
            export_default(inputs.spectra);
        end
        
        if inputs.exit
            exit;
        end
    end

init_globals;
load_settings;
init_gui;

if ~handle_arguments
    close(gcf);
    return
end

    function init_channels()
        iTRAQType = {};
        iTRAQ_masses = [];
        iTRAQ_labels = {};

        SILAC = false;
        SILAC_R6 = false;
        SILAC_R10 = false;
        SILAC_K6 = false;
        SILAC_K8 = false;
        
        iTRAQ_4_plex_masses = [ ...
            114.1106798, ...
            115.1077147, ...
            116.1110695, ...
            117.1144243 ...
        ];

        iTRAQ_4_plex_labels = { ...
            '114', ...
            '115', ...
            '116', ...
            '117' ...
        };

        TMT_6_plex_masses = [ ...
            126.127726, ...
            127.124761, ...
            128.134436, ...
            129.131471, ...
            130.141145, ...
            131.138180 ...
        ];

        TMT_6_plex_labels = { ...
            '126', ...
            '127', ...
            '128', ...
            '129', ...
            '130', ...
            '131' ...
        };

        iTRAQ_8_plex_masses = [ ...
            113.107873, ...
            114.111228, ...
            115.108263, ...
            116.111618, ...
            117.114973, ...
            118.112008, ...
            119.115363, ...
            121.122072 ...
        ];

        iTRAQ_8_plex_labels = { ...
            '113', ...
            '114', ...
            '115', ...
            '116', ...
            '117', ...
            '118', ...
            '119', ...
            '121' ...
        };

        %%% XXX: Are these all correct? 230 / 248?
        TMT_10_plex_masses = [ ...
            126.127726, ...
            127.124761, ...
            127.131081, ...
            128.128116, ...
            128.134436, ...
            129.131471, ...
            129.137790, ...
            130.134825, ...
            130.141145, ...
            131.138180, ...
            230.1694, ...
            248.1802 ...
        ];

        TMT_10_plex_labels = { ...
            '126', ...
            '127N', ...
            '127C', ...
            '128N', ...
            '128C', ...
            '129N', ...
            '129C', ...
            '130N', ...
            '130C', ...
            '131', ...
            '230', ...
            '248' ...
        };
    end

    function init_globals()
        RAW_filename = '';
        RAW_path = '';
        XML_filename = '';
        XML_path = '';
        OUT_path = '';
        filename = '';
        SL_path = '';
        SL_filename = '';

        % Set a base path from which we expect to find the utility files
        base_dir = fileparts(fileparts(mfilename('fullpath')));
        rel_path = '';
        
        % If this is deployed as "CAMV.exe", this path is a folder
        % in the user's temporary directory, in a subfolder that was the
        % path to those files when the project was compiled.
        if isdeployed
            base_dir = ctfroot;
            % rel_path = '\Users\Nader\Dropbox (MIT)\White Lab\CAMV';
        end
        
        % String these together to find msconvert.exe and images
        msconvert_full_path = fullfile(base_dir, rel_path, '\ProteoWizard\ProteoWizard 3.0.9205\msconvert.exe');
        images_dir = fullfile(base_dir, rel_path, '\images\');
        
        % Otherwise just search that folder for any occurance of files
        % with those names.
        if ~exist(msconvert_full_path, 'file')
            % Use system, not systemsafe. dir has issues with escaping
            % backslashes.
            [~, msconvert_full_path] = system(['dir /s/b ', base_dir, '\*msconvert.exe']);
            msconvert_full_path = strtrim(msconvert_full_path);
        end

        if ~exist(images_dir, 'dir')
            [~, images_dir] = system(['dir /s/b ', base_dir, '\*images']);
            images_dir = strtrim(images_dir);
        end
        
        data = {};
        mtree = 0;
        jtree = 0;
        prev_node = '';

        init_channels;

        CID_tol = 1000;
        HCD_tol = 10;

        accept_list = {};
        maybe_list = {};
        reject_list = {};

        new_accept_list = {};
        new_maybe_list = {};

        cont_thresh = 100;
        % this needs to be changed to actual fragmentation window (see ^^^)
        cont_window = 1;

        b_names_keep = {};
        y_names_keep = {};

        % Maximum number of peaks in MS2 before excluded
        max_num_peaks = 50;
    end

    function init_gui()
        % Tree
        h = figure( ...
            'pos', [150, 100, 1200, 600], ...
            'Units', 'normalized', ...
            'KeyPressFcn', @keyInput ...
        );
        set(gcf, ...
            'name', 'Spectrum Validation', ...
            'numbertitle', 'off', ...
            'MenuBar', 'none' ...
        );

        % Buttons
        handle1 = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Accept', ...
            'Enable', 'off', ...
            'BackgroundColor', 'g', ...
            'Units', 'normalized', ...
            'Position', [0.61, 0.02, .06, .05], ...
            'Callback', @accept ...
        );

        handle2 = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Maybe', ...
            'Enable', 'off', ...
            'BackgroundColor', [1, 0.5, 0.2], ...
            'Units', 'normalized', ...
            'Position', [0.68, 0.02, .06, .05], ...
            'Callback', @maybe ...
        );

        handle3 = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Reject', ...
            'Enable', 'off', ...
            'BackgroundColor', 'r', ...
            'Units', 'normalized', ...
            'Position', [0.75, 0.02, .06, .05], ...
            'Callback', @reject ...
        );

        handle_RR = uicontrol( ...
            'KeyPressFcn', @keyInput, ...
            'Enable', 'off', ...
            'Visible', 'off' ...
        );

        handle_export = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Export...', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.88, 0.02, .1, .05], ...
            'Callback', @display_export ...
        );

        handle_reset = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Reset Session', ...
            'Enable', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.91, 0.93, .08, .05], ...
            'Callback', @resetGUI ...
        );

        % handle_print_curr_ms2 = uicontrol('Style', 'pushbutton', 'String', 'Print Current MS2',...
        %     'Position', [1080 0 100 20],...
        %     'Callback', @print_ms2);

        handle_process_anyway = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Process Anyway', ...
            'Enable', 'off', ...
            'Visible', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.21, 0.85, .1, .05], ...
            'Callback', @process_anyway ...
        );

        handle_search = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Search', ...
            'Enable', 'off', ...
            'Visible', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.02, 0.02, .06, .05], ...
            'Callback', @search ...
        );

        handle_transfer = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Transfer Choices', ...
            'Enable', 'off', ...
            'Visible', 'off', ...
            'Units', 'normalized', ...
            'Position', [0.09, 0.02, .09, .05], ...
            'Callback', @transfer ...
        );

        handle_file = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Get File', ...
            'Units', 'normalized', ...
            'Position', [0.20, 0.02, .06, .05], ...
            'Callback', @upload ...
        );
        handle_file_continue = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Load Session', ...
            'Units', 'normalized', ...
            'Position', [0.27, 0.02, .08, .05], ...
            'Callback', @load_session ...
        );
        handle_file_save = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Save Session', ...
            'Units', 'normalized', ...
            'Position', [0.36, 0.02, .08, .05], ...
            'Callback', @save_session, ...
            'Enable', 'off' ...
        );

        % handle_settings = uicontrol('Style', 'pushbutton', 'String', 'Change Settings', 'Position', [10, 150, 100, 20], 'Callback', @change_settings);

        ax0 = axes( ...
            'Position', [0, 0, 1, 1], ...
            'Visible', 'off' ...
        );
        handle_print_now = text( ...
            .25, .9, '', ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );
        handle_print_code_now = text( ...
            .25, .85, '', ...
            'Units', 'normalized', ...
            'Interpreter', 'none', ...
            'FontWeight', 'bold', ...
            'Color', 'r' ...
        );

        % MS2 data
        ax1 = axes( ...
            'Position', [.2, .125, .6, .7], ...
            'TickDir', 'out', ...
            'box', 'off' ...
        );

        % MS2 Peak Assignments
        ax1_assign = axes( ...
            'Position', [.2, .125, .6, .7], ...
            'Visible', 'off' ...
        );
        linkaxes([ax1, ax1_assign], 'xy');

        % Write Information onto plot
        ax1_info = axes( ...
            'Position', [.2, .125, .6, .7], ...
            'Visible', 'off' ...
        );

        % Precursor Window
        ax2 = axes( ...
            'Position', [.84, .5, .14, .25], ...
            'TickDir', 'out', ...
            'box', 'off' ...
        );
        text( ...
            .5, 1.1, 'Precursor', ...
            'HorizontalAlignment', 'center' ...
        );

        % Now initialized after iTRAQ presence is confirmed
        % iTRAQ Window
        ax3 = axes( ...
            'Position', [.84, .125, .14, .25], ...
            'TickDir', 'out', ...
            'box', 'off', ...
            'Visible', 'off' ...
        );
        % text(.5,1.1,'iTRAQ', 'HorizontalAlignment', 'center');

        zoom_is_clicked = 0;
        start_zoom = 0;
        hold_zoom_start = 0;
        hold_zoom_end = 0;
        is_zoomed = 0;
        
        % Precursor Contamination
        handle_prec_cont = uicontrol( ...
            'Style', 'checkbox', ...
            'String', 'Exclude Precursor Contamination?', ...
            'Units', 'normalized', ...
            'Position', [0.01, 0.61, .16, .05], ...
            'Callback', @prec_cont_checked ...
        );

        handle_threshold = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.05, 0.55, .04, .04], ...
            'Enable', 'off', ...
            'string', num2str(cont_thresh) ...
        );

        handle_window = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.05, 0.50, .04, .04], ...
            'Enable', 'off', ...
            'string', num2str(cont_window) ...
        );

        function prec_cont_checked(~, ~)
            if get(handle_prec_cont, 'Value')
                set(handle_threshold, 'Enable', 'on');
                set(handle_window, 'Enable', 'on');
            else
                set(handle_threshold, 'Enable', 'off');
                set(handle_window, 'Enable', 'off');
            end
        end

        % Scan Number List
        % handle_scan_number_list = uicontrol('Style','checkbox','String','Use scan list (XLS)?','Position',[10,400,200,20]);

        axes(ax0);
        handle_percent_text = text( ...
            0.1, 0.575, '%', ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );
        handle_mz_text = text( ...
            0.1, 0.525, '+/- m/z', ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );

        % MS2 Tolerances
        handle_CID_tol = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.1, 0.40, .04, .04], ...
            'Enable', 'on', ...
            'string', '1000' ...
        );
        handle_CID_text = text( ...
            0.02, 0.425, 'CID Tol.(ppm)', ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );

        handle_HCD_tol = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [0.1, 0.35, .04, .04], ...
            'Enable', 'on', ...
            'string', '10' ...
        );
        handle_HCD_text = text( ...
            0.02, 0.375, 'HCD Tol.(ppm)', ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );
    
        handle_batch_process = uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Batch Process', ...
            'Units', 'normalized', ...
            'Position', [0.05, 0.25, .08, .05], ...
            'Callback', @batch_process ...
        );
    end

    function resetGUI(~, ~)
        
        resetflag = 0;
        
        choice = questdlg('Are you sure you want to reset?', ...
            'Reset CAMV?', ...
            'Save and Reset','Reset','Cancel','Save and Reset');
        % Handle response
        switch choice
            case 'Save and Reset'
                save_session
                resetflag = 1;
            case 'Reset'
                resetflag = 1;
        end
        
        if resetflag == 1
            
            close(gcf)
            
            init_globals;
            load_settings;
            init_gui;
        end
    end

    %%% Zoom in upon user clicks to the MS2 window
    %
    % Two single clicks define boundaries of zoom window
    % Double click zooms out
    function zoom_MS2(~,~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue,'\.','split');
        
        if strcmp(get(gcf,'SelectionType'),'open')
            % Double click zooms out
            cla(ax1);
            cla(ax1_assign);
            cla(ax1_info);
            
            axes(ax1);
            set(gca, 'TickDir', 'out', 'box', 'off');
            stem(data{str2num(scan_curr{1})}.scan_data(:,1),data{str2num(scan_curr{1})}.scan_data(:,2),'Marker', 'none');
            
            axes(ax1_assign)
            display_ladder(str2num(scan_curr{1}),str2num(scan_curr{2}));
            plot_assignment(str2num(scan_curr{1}),str2num(scan_curr{2}));
            
            axes(ax1_info)
            text(0.01, 0.95, ['Scan Number: ', num2str(data{str2num(scan_curr{1})}.scan_number)]);
            text(0.01, 0.90, ['MASCOT Score: ', num2str(round(data{str2num(scan_curr{1})}.pep_score))]);
            
            set(ax1, 'ButtonDownFcn', @zoom_MS2);
            zoom_is_clicked = 0;
            is_zoomed = 0;
            hold_zoom_start = 0;
            hold_zoom_end = 0;
        else
            if zoom_is_clicked
                %                 print_now('');
                % End range selection for zoom
                temp = get(ax1,'CurrentPoint');
                end_zoom = temp(1,1);
                
                if start_zoom > end_zoom
                    temp = end_zoom;
                    end_zoom = start_zoom;
                    start_zoom = temp;
                end
                
                hold_zoom_start = start_zoom;
                hold_zoom_end = end_zoom;
                is_zoomed = 1;
                
                % Find indicies of start and end of user selected zoom
                % window
                x1 = find(data{str2num(scan_curr{1})}.scan_data(:,1) > start_zoom);
                x2 = find(data{str2num(scan_curr{1})}.scan_data(:,1) < end_zoom);
                
                x_used = intersect(x1,x2);
                
                if isempty(x_used)
                    cla(ax1);
                    cla(ax1_assign);
                    cla(ax1_info);
                    
                    axes(ax1);
                    set(gca, ...
                        'TickDir', 'out', ...
                        'box', 'off' ...
                    );
                    stem( ...
                        data{str2num(scan_curr{1})}.scan_data(:,1), ...
                        data{str2num(scan_curr{1})}.scan_data(:,2), ...
                        'Marker', 'none' ...
                    );
                    
                    axes(ax1_assign)
                    display_ladder(str2num(scan_curr{1}), str2num(scan_curr{2}));
                    plot_assignment(str2num(scan_curr{1}), str2num(scan_curr{2}));
                    
                    axes(ax1_info)
                    text(0.01, 0.95, ['Scan Number: ', num2str(data{str2num(scan_curr{1})}.scan_number)]);
                    text(0.01, 0.90, ['MASCOT Score: ', num2str(round(data{str2num(scan_curr{1})}.pep_score))]);
                    
                    set(ax1, 'ButtonDownFcn', @zoom_MS2);
                    zoom_is_clicked = 0;
                    is_zoomed = 0;
                    hold_zoom_start = 0;
                    hold_zoom_end = 0;
                else
                    
                    cla(ax1);
                    cla(ax1_assign);
                    cla(ax1_info);
                    
                    set(ax1, 'XLim', [start_zoom, end_zoom]);
                    
                    axes(ax1);
                    set(gca, ...
                        'TickDir', 'out', ...
                        'box', 'off' ...
                    );
                    stem( ...
                        data{str2num(scan_curr{1})}.scan_data(x_used, 1), ...
                        data{str2num(scan_curr{1})}.scan_data(x_used, 2), ...
                        'Marker', 'none' ...
                    );
                    
                    axes(ax1_assign)
                    display_ladder(str2num(scan_curr{1}), str2num(scan_curr{2}));
                    plot_assignment(str2num(scan_curr{1}), str2num(scan_curr{2}), start_zoom, end_zoom);  %ABCD
                    
                    % Scale y-axis for zoomed window
                    set(ax1, 'YLim', [0, 1.25*max(data{str2num(scan_curr{1})}.scan_data(x_used,2))]);
                    
                    axes(ax1_info)
                    text(0.01, 0.95, ['Scan Number: ', num2str(data{str2num(scan_curr{1})}.scan_number)]);
                    text(0.01, 0.90, ['MASCOT Score: ', num2str(round(data{str2num(scan_curr{1})}.pep_score))]);
                    
                    set(ax1, 'ButtonDownFcn', @zoom_MS2);
                    zoom_is_clicked = 0;
                end
                
            else
                %                 print_now('clicked');
                % Begin range selection for zoom.
                temp = get(ax1,'CurrentPoint');
                start_zoom = temp(1,1);
                zoom_is_clicked = 1;
            end
        end
    end

    %%% Handle selecting elements of the tree from the spectra view
    function update_tree()
        % Move focus in tree to newly selected scan number
        tree_row = mtree.Tree.getSelectionRows();
        mtree.Tree.scrollRowToVisible(tree_row);
        mtree.FigureComponent.getHorizontalScrollBar.setValue(0);
        
        mousePressedCallback();
    end
   
    function select_next()
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        next_node = [];
        
        import javax.swing.tree.TreePath;
        node_path = TreePath(node.getPath);
        if get(node, 'ChildCount') > 0 && jtree.isExpanded(node_path)
            next_node = get(node, 'FirstChild');
        end
        
        if isempty(next_node)
            next_node = get(node, 'NextSibling');
        end
        
        if isempty(next_node)
            next_node = get(node, 'NextNode');
        end
        
        if ~isempty(next_node)
            mtree.setSelectedNode(next_node);
            update_tree();
        end
    end

    function select_previous()
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        previous_node = get(node, 'PreviousSibling');
        
        if ~isempty(previous_node)
            import javax.swing.tree.TreePath;
            node_path = TreePath(previous_node.getPath);
            if get(previous_node, 'ChildCount') > 0 && jtree.isExpanded(node_path)
                previous_node = get(previous_node, 'LastChild');
            end
        end
        
        if isempty(previous_node)
            previous_node = get(node, 'PreviousNode');
        end
        
        if ~isempty(previous_node)
            mtree.setSelectedNode(previous_node);
            update_tree();
        end
    end
    
    function select_parent()
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        if get(node, 'Root')
            return
        end
        
        import javax.swing.tree.TreePath;
        node_path = TreePath(node.getPath);
        if get(node, 'ChildCount') > 0 && jtree.isExpanded(node_path)
            jtree.collapsePath(node_path);
            return;
        end
        
        node = get(node, 'Parent');
        
        mtree.setSelectedNode(node);
        update_tree();
    end
    
    function select_child()
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        if get(node, 'Leaf')
            return
        end
        
        import javax.swing.tree.TreePath;
        node_path = TreePath(node.getPath);
        if ~jtree.isExpanded(node_path)
            if ~get(node, 'Root')
                jtree.expandPath(node_path);
                return
            end
        end
            
        node = get(node, 'FirstChild');
        
        mtree.setSelectedNode(node);
        update_tree();
    end
    
    %%% Handle key press events in spectra
    function keyInput(~, event)
        switch event.Character
            case 'a'
                accept();
            case 's'
                maybe();
            case 'd'
                reject();
        end
        
        switch event.Key
            case 'uparrow'
                select_previous();
            case 'downarrow'
                select_next();
            case 'leftarrow'
                select_parent();
            case 'rightarrow'
                select_child();
        end
    end

    function assignment = check_node_is_assignment(node)
        assignment = ~isempty(regexp(node.getValue, '\.', 'once'));
    end

    function accept(~, ~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        if ~check_node_is_assignment(node)
            return;
        end
        
        node.setIcon(im2java(imread(fullfile(images_dir, 'green.jpg'))));
        jtree.treeDidChange();
        
        % Add to list to be printed
        id = regexp(node.getValue, '\.', 'split');
        scan = id{1};
        choice = id{2};
        
        data{str2num(scan)}.fragments{str2num(choice)}.status = 1;
        
        % Check if the scan was already accepted
        for i = 1:length(accept_list)
            if strcmp(accept_list{i}.scan, scan) && ...
                    strcmp(accept_list{i}.choice, choice)
                return;
            end
        end
        
        % Otherwise accept it and remove it from the reject / maybe list
        accept_list{end + 1}.scan = scan;
        accept_list{end}.choice = choice;

        for i = 1:length(reject_list)
            if strcmp(reject_list{i}.scan, scan) && ...
                    strcmp(reject_list{i}.choice, choice)
                reject_list(i) = '';
                return;
            end
        end

        for i = 1:length(maybe_list)
            if strcmp(maybe_list{i}.scan, scan) && ...
                    strcmp(maybe_list{i}.choice, choice)
                maybe_list(i) = '';
                return;
            end
        end
    end

    function reject(~, ~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        if ~check_node_is_assignment(node)
            return;
        end
        
        node.setIcon(im2java(imread(fullfile(images_dir, 'red.jpg'))));
        jtree.treeDidChange();
        
        id = regexp(node.getValue, '\.', 'split');
        scan = id{1};
        choice = id{2};
        
        data{str2num(scan)}.fragments{str2num(choice)}.status = 3;
        
        % Check if the scan was already rejected
        for i = 1:length(reject_list)
            if strcmp(reject_list{i}.scan, scan) && ...
                    strcmp(reject_list{i}.choice, choice)
                return;
            end
        end
        
        % Otherwise reject it and remove it from the accept / maybe list
        reject_list{end + 1}.scan = scan;
        reject_list{end}.choice = choice;

        for i = 1:length(accept_list)
            if strcmp(accept_list{i}.scan, scan) && ...
                    strcmp(accept_list{i}.choice, choice)
                accept_list(i) = '';
                return;
            end
        end

        for i = 1:length(maybe_list)
            if strcmp(maybe_list{i}.scan, scan) && ...
                    strcmp(maybe_list{i}.choice, choice)
                maybe_list(i) = '';
                return;
            end
        end
    end

    function maybe(~, ~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        if ~check_node_is_assignment(node)
            return;
        end
        
        node.setIcon(im2java(imread(fullfile(images_dir, 'orange.jpg'))));
        jtree.treeDidChange();
        
        % Add to list to be printed
        id = regexp(node.getValue, '\.', 'split');
        scan = id{1};
        choice = id{2};
        
        data{str2num(scan)}.fragments{str2num(choice)}.status = 2;
        
        % Check if the scan was already maybed
        for i = 1:length(maybe_list)
            if strcmp(maybe_list{i}.scan, scan) && ...
                    strcmp(maybe_list{i}.choice, choice)
                return;
            end
        end
        
        % Otherwise maybe it and remove it from the reject / accept list
        maybe_list{end + 1}.scan = scan;
        maybe_list{end}.choice = choice;

        for i = 1:length(reject_list)
            if strcmp(reject_list{i}.scan, scan) && ...
                    strcmp(reject_list{i}.choice, choice)
                reject_list(i) = '';
                return;
            end
        end

        for i = 1:length(accept_list)
            if strcmp(accept_list{i}.scan, scan) && ...
                    strcmp(accept_list{i}.choice, choice)
                accept_list(i) = '';
                return;
            end
        end
    end

    %%% Print plots for scans in a given peptide list.
    function write_spectra(lst, path)
        function seq = fix_seq(seq)
            seq = regexprep(seq, 's', '(s)');
            seq = regexprep(seq, 't', '(t)');
            seq = regexprep(seq, 'y', '(y)');
            seq = regexprep(seq, 'm', '(m)');
            seq = regexprep(seq, 'k', '(k)');
        end
        function fig_name = fix_fig_name(fig_name)
            fig_name = regexprep(fig_name, '/', '-');
            fig_name = regexprep(fig_name, ':', '-');
            fig_name = regexprep(fig_name, '\.', '');
        end
        dir_path = [path, '\'];
        if ~isempty(lst)
            if exist(dir_path, 'dir') == 0
                % Make output directory
                mkdir(dir_path);
            else
                % Remove files that are no longer accepted
                dir_contents = dir(dir_path);
                
                % Precompute the list of figure names
                fig_names = cell(length(lst));
                for j = 1:length(lst)
                    scan = str2num(lst{j}.scan);
                    id = str2num(lst{j}.choice);

                    seq = fix_seq(data{scan}.fragments{id}.seq);
                    fig_name = fix_fig_name( ...
                        [data{scan}.protein, ' - ', num2str(data{scan}.scan_number), ' - ', seq] ...
                    );
                    fig_names{j} = [fig_name, '.pdf'];
                end
                
                % Skip '.' and '..'
                for i = 3:length(dir_contents)
                    if any(strcmp(dir_contents(i).name, fig_names))
                        delete(fullfile(dir_path, dir_contents(i).name));
                    end
                end
            end
            % Print new figures
            for i = 1:length(lst)
                scan = str2num(lst{i}.scan); %#ok<*ST2NM>
                id = str2num(lst{i}.choice);
                
                seq = fix_seq(data{scan}.fragments{id}.seq);
                fig_name = fix_fig_name( ...
                    [data{scan}.protein, ' - ', num2str(data{scan}.scan_number), ' - ', seq] ...
                );
                
                if ~exist(fullfile(dir_path, [fig_name, '.pdf']), 'file')
                    print_pdf(scan, id, fullfile(dir_path, fig_name));
                end
            end
        else
            delete([dir_name, '*.pdf']);
        end
    end
    
    %%% Write a list of peptides and their associated iTRAQ data for a
    %%% given peptide list.
    function write_list(lst, path)
        [out_dir, ~, ~] = fileparts(path);
        
        if exist(out_dir, 'dir') == 0
            mkdir(out_dir);
        end
        
        out_path = [path, '.xls'];
        
        if ~isempty(lst)
            if ~strcmp(iTRAQType{1},'None')
                iTRAQ_to_Excel(lst, out_path);
            elseif SILAC
                SILAC_to_Excel(lst, out_path);
            else
                unlabelled_to_Excel(lst, out_path);
            end
        else
            delete(out_path)
        end
    end

    %%% This function handles exporting the list of accepted / rejected /
    %%% maybe'd peptides and their annotated spectra.
    function display_export(~, ~)
        fig = figure( ...
            'pos', [400, 400, 700, 150] ...
            ... % 'WindowStyle', 'modal' ...
        );
        set(fig, ...
            'name', 'Export', ...
            'numbertitle', 'off', ...
            'MenuBar', 'none' ...
        );
        set(gca, ...
            'Visible', 'off', ...
            'Position', [0, 0, 1, 1] ...
        );
        
        accept_out = fullfile(OUT_path, filename, 'accept');
        maybe_out = fullfile(OUT_path, filename, 'maybe');
        reject_out = fullfile(OUT_path, filename, 'reject');
        
        text( ...
            .125, .85, 'Export?', ...
            'Units', 'normalized' ...
        );
        text( ...
            .2, .85, 'Print Spectra?', ...
            'Units', 'normalized' ...
        );
        text( ...
            .35, .85, ...
            'Base Path (+ .xls, + \\<Protein> - <Scan ID> - <Sequence>.pdf)', ...
            'Units', 'normalized' ...
        );
        
        text( ...
            .03, .65, 'Accept List:', ...
            'Units', 'normalized' ...
        );
        handle_enable_accept = uicontrol( ...
            'Style', 'checkbox', ...
            'Units', 'normalized', ...
            'Position', [.15, .6, 0.1, 0.1], ...
            'Value', 1, ...
            'Callback', @enable_accept ...
        );
        handle_spectra_accept = uicontrol( ...
            'Style', 'checkbox', ...
            'Units', 'normalized', ...
            'Position', [.25, .6, 0.1, 0.1] ...
        );
        handle_accept = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [.35, .6, 0.55, 0.15], ...
            'Enable', 'on', ...
            'String', accept_out, ...
            'HorizontalAlignment', 'left' ...
        );
        handle_select_accept = uicontrol( ...
            'Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [.92, .6, 0.04, 0.15], ...
            'String', '...', ...
            'Callback', @select_accept ...
        );
        accept_list_handles = [handle_spectra_accept, handle_accept, handle_select_accept];
        
        text( ...
            .03, .48, 'Maybe List:', ...
            'Units', 'normalized' ...
        );
        handle_enable_maybe = uicontrol( ...
            'Style', 'checkbox', ...
            'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [.15, .425, 0.1, 0.1], ...
            'Callback', @enable_maybe ...
        );
        handle_spectra_maybe = uicontrol( ...
            'Style', 'checkbox', ...
            'Units', 'normalized', ...
            'Position', [.25, .425, 0.1, 0.1] ...
        );
        handle_maybe = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [.35, .425, 0.55, 0.15], ...
            'Enable', 'on', ...
            'String', maybe_out, ...
            'HorizontalAlignment', 'left' ...
        );
        handle_select_maybe = uicontrol( ...
            'Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [.92, .425, 0.04, 0.15], ...
            'String', '...', ...
            'Callback', @select_maybe ...
        );
        maybe_list_handles = [handle_spectra_maybe, handle_maybe, handle_select_maybe];
        
        text( ...
            .03, .31, 'Reject List:', ...
            'Units', 'normalized' ...
        );
        handle_enable_reject = uicontrol( ...
            'Style', 'checkbox', ...
            'Value', 1, ...
            'Units', 'normalized', ...
            'Position', [.15, .25, 0.1, 0.1], ...
            'Callback', @enable_reject ...
        );
        handle_spectra_reject = uicontrol( ...
            'Style', 'checkbox', ...
            'Units', 'normalized', ...
            'Position', [.25, .25, 0.1, 0.1] ...
        );
        handle_reject = uicontrol( ...
            'Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [.35, .25, 0.55, 0.15], ...
            'Enable', 'on', ...
            'String', reject_out, ...
            'HorizontalAlignment', 'left' ...
        );
        handle_select_reject = uicontrol( ...
            'Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [.92, .25, 0.04, 0.15], ...
            'String', '...', ...
            'Callback', @select_reject ...
        );
        reject_list_handles = [handle_spectra_reject, handle_reject, handle_select_reject];
        
        uicontrol(...
            'Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [.8, .05, 0.15, 0.15], ...
            'String', 'Export', ...
            'Callback', @call_export ...
        );
        
        function enable_accept(~, ~)
            if get(handle_enable_accept, 'Value')
                on_off = 'on';
            else
                on_off = 'off';
            end
            for i=1:numel(accept_list_handles)
                set(accept_list_handles(i), 'Enable', on_off);
            end
        end
        function enable_maybe(~, ~)
            if get(handle_enable_maybe, 'Value')
                on_off = 'on';
            else
                on_off = 'off';
            end
            for i=1:numel(maybe_list_handles)
                set(maybe_list_handles(i), 'Enable', on_off);
            end
        end
        function enable_reject(~, ~)
            if get(handle_enable_reject, 'Value')
                on_off = 'on';
            else
                on_off = 'off';
            end
            for i=1:numel(reject_list_handles)
                set(reject_list_handles(i), 'Enable', on_off);
            end
        end
        function select_accept(~, ~)
            [out_filename, out_path] = uiputfile('*');
            if out_path
                set(handle_accept, 'String', [out_path, out_filename]);
            end
        end
        function select_maybe(~, ~)
            [out_filename, out_path] = uiputfile('*');
            if out_path
                set(handle_maybe, 'String', [out_path, out_filename]);
            end
        end
        function select_reject(~, ~)
            [out_filename, out_path] = uiputfile('*');
            if out_path
                set(handle_reject, 'String', [out_path, out_filename]);
            end
        end
        function call_export(~, ~)
            handles = [...
                [handle_enable_accept, handle_spectra_accept, handle_accept]; ...
                [handle_enable_maybe, handle_spectra_maybe, handle_maybe]; ...
                [handle_enable_reject, handle_spectra_reject, handle_reject] ...
            ];
            lists = {accept_list, maybe_list, reject_list};
            for i=1:length(lists)
                lst = lists{i};
                enabled = get(handles(i, 1), 'Value');
                spectra = get(handles(i, 2), 'Value');
                path = get(handles(i, 3), 'String');
                
                if enabled
                    export(lst, spectra, path);
                end
            end
            close(fig);
        end
    end

    function export_default(spectra)
        accept_out = fullfile(OUT_path, filename, 'accept');
        maybe_out = fullfile(OUT_path, filename, 'maybe');
        reject_out = fullfile(OUT_path, filename, 'reject');
        
        export(accept_list, spectra, accept_out);
        export(maybe_list, spectra, maybe_out);
        export(reject_list, spectra, reject_out);
    end

    function export(lst, spectra, path)
        if isempty(lst)
            return;
        end

        write_list(lst, path);

        if spectra
            write_spectra(lst, path);
        end
    end

    %%% Used to make publication quality tiff's of single MS2 scans
    function print_ms2(~, ~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue,'\.','split');
        scan = str2num(scan_curr{1});
        id = str2num(scan_curr{2});
        
        seq = data{scan}.fragments{id}.seq;
        protein = data{scan}.protein;
        charge_state = data{scan}.pep_exp_z;
        scan_number = data{scan}.scan_number;
        
        %         b_ions = data{scan}.fragments{id}.b_ions;
        %         y_ions = data{scan}.fragments{id}.y_ions;
        
        b_used = zeros(length(seq),1);
        y_used = zeros(length(seq),1);
        
        [R,~] = size(data{scan}.fragments{id}.validated);
        for r = 1:R
            if ~isempty(data{scan}.fragments{id}.validated{r,2})
                if strcmp(data{scan}.fragments{id}.validated{r,2}(1),'a') || strcmp(data{scan}.fragments{id}.validated{r,2}(1),'b')
                    [~,~,~,d] = regexp(data{scan}.fragments{id}.validated{r,2},'[0-9]*');
                    b_used(str2num(d{1})) = 1;
                elseif strcmp(data{scan}.fragments{id}.validated{r,2}(1),'y')
                    [~, ~,~,d] = regexp(data{scan}.fragments{id}.validated{r,2},'[0-9]*');
                    y_used(str2num(d{1})) = 1;
                end
            end
        end
        
        fig2 = figure('pos', [100 100 800 400]);
        set(gca,'Visible','off');
        %         % Print PDF friendly scan information and ladder
        %         text(-40, 665, protein, 'Units', 'pixels', 'FontSize', 10);
        %         text(-40, 650, ['Charge State: +', num2str(charge_state)], 'Units', 'pixels', 'FontSize', 10);
        %         text(-40, 635, ['Scan Number: ', num2str(scan_number)], 'Units', 'pixels', 'FontSize', 10);
        %         text(-40, 620, ['File Name: ', filename, '.raw'], 'Units', 'pixels', 'FontSize', 10, 'Interpreter', 'none');
        
        x_start = -40;
        y_start = 325;
        
        num_font_size = 5;
        
        %         space_x = 20;
        space_x = 10;
        %         space_y = 20;
        
        %         text(x_start, y_start + space_y, num2str(b_ions(1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
        text(x_start, y_start, seq(1), 'Units', 'pixels', 'HorizontalAlignment', 'Center')
        
        prev = x_start;
        
        for i = 2:length(seq)
            if b_used(i-1) == 1 && y_used(end-i+1) == 1
                text(prev + space_x, y_start, '\color{red}^{\rceil}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            elseif b_used(i-1) == 1 && y_used(end-i+1) == 0
                text(prev + space_x, y_start, '\color{red}^{\rceil}\color{black}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            elseif b_used(i-1) == 0 && y_used(end-i+1) == 1
                text(prev + space_x, y_start, '^{\rceil}\color{red}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            else
                text(prev + space_x, y_start, '^{\rceil}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            end
            
            %             if i < length(seq)
            %                 text(prev + 2*space_x, y_start + space_y, num2str(b_ions(i)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            %             end
            text(prev + 2*space_x, y_start, seq(i), 'Units', 'pixels', 'HorizontalAlignment', 'Center');
            %             text(prev + 2*space_x, y_start - space_y, num2str(y_ions(end-i+1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            prev = prev + 2*space_x;
        end
        
        
        ax1_pdf = axes('Position', [.12,.15,.8,.65], 'TickDir', 'out', 'box', 'off');
        
        axes(ax1_pdf);
        stem(data{scan}.scan_data(:,1),data{scan}.scan_data(:,2),'Marker', 'none');
        plot_assignment(scan,id);
        set(gca, 'TickDir', 'out', 'box', 'off');
        ylim([0,1.25*max(data{scan}.scan_data(:,2))]);
        
        x_start = 0.95 * data{scan}.fragments{id}.validated{1,1};
        x_end = 1.05 * data{scan}.fragments{id}.validated{end,1};
        
        xlim([x_start,x_end]);
        xlabel('m/z', 'Fontsize', 20);
        ylabel('Intensity', 'Fontsize', 20);
        
        set(gcf,'PaperPositionMode','auto');
        print(fig2, '-dtiff', '-r600', 'curr_ms2');
        close(fig2);
    end

    function load_settings()
        
    end

    function save_settings()
        
    end

    function change_settings(~, ~)
        h2 = figure('pos',[400,400,500,200], 'WindowStyle', 'modal');
        set(gcf,'name','Settings','numbertitle','off', 'MenuBar', 'none');
        set(gca,'Visible', 'off', 'Position', [0 0 1 1]);
        
        text(10, 150, 'msconvert path:', 'Units', 'pixels');
        handle_msconvert = uicontrol('Style','edit','Position',[110 138 300 20],'Enable','on', 'HorizontalAlignment', 'left');
        uicontrol('Style', 'pushbutton', 'Position', [420 138, 20, 20], 'String', '...', 'Callback', @select_msconvert);
        
        function select_msconvert(~, ~)
            [msconvert_filename, msconvert_path] = uigetfile({'*.exe','EXE Files'}, 'msconvert Location', [msconvert_path, msconvert_filename]);
            set(handle_RAW, 'String', [msconvert_path, msconvert_filename]);
        end
        
    end

    %%% Process multiple files from the same folder. Ensure that RAW and XML are
    %%% in the same folder with the same name. If scan lists are to be used, they
    %%% must also be in the same folder with the same names.
    function batch_process(~, ~)
        
        [names, path] = uigetfile({'*.raw','RAW Files'}, 'MultiSelect', 'on');

        if isequal(names, 0)
            return;
        end
        
        %       if ~isempty(regexp(path, ' '))
        %           msgbox('Please choose a RAW file path without spaces.','Warning');
        %       else
        if ischar(names)
            % Only one file selected
            filename = names;
            filename = regexprep(filename,'.RAW','');
            filename = regexprep(filename,'.raw','');
            filename = regexprep(filename,'.xml','');
            
            if ~exist([path, filename, '.xml'], 'file')
                msgbox(['File not found: ',path,filename,'.xml'])
                return;
            end
            
            filename = names;
            filename = regexprep(filename,'.RAW','');
            filename = regexprep(filename,'.raw','');
            filename = regexprep(filename,'.xml','');

            RAW_path = path;
            RAW_filename = [filename, '.RAW'];
            XML_path = path;
            XML_filename = [filename, '.XML'];
            SL_path = path;
            SL_filename = [filename,'.xls'];
            SAVE_path = path;
            SAVE_filename = [filename, '.mat'];

            try
                validate_spectra();
            catch err
                print_code_now(['Error validating spectra: ', err.identifier, '. Please reset.'])
                set(handle_reset,'Enable','on');
            end


            if ~isemtpy(data)
                print_now(['Saving...', filename]);
                save( ...
                    [SAVE_path, SAVE_filename], ...
                    'data', 'iTRAQType', 'iTRAQ_masses', 'SILAC', 'SILAC_R6', 'SILAC_R10', 'SILAC_K6', 'SILAC_K8', ...
                    'cont_thresh', 'cont_window', 'HCD_tol', 'CID_tol', 'OUT_path', ...
                    '-v7' ...
                );
                print_now('');
            end

            data = {};
            init_channels;
        else
            % Multiple RAW files selected
            files_not_found = {};
            for i = 1:length(names)
                filename = names{i};
                filename = regexprep(filename,'.RAW','');
                filename = regexprep(filename,'.raw','');
                filename = regexprep(filename,'.xml','');
                
                if ~exist([path, filename, '.xml'], 'file')
                    files_not_found{end+1} = [path,filename,'.xml'];
                end
                
            end
            if ~isempty(files_not_found)
                error_msg = 'File(s) not found:\n';
                for i = 1:length(files_not_found)
                    error_msg = [error_msg, files_not_found{i}, '\n'];
                end
                msgbox(error_msg);
            else
                for i = 1:length(names)
                    filename = names{i};
                    filename = regexprep(filename,'.RAW','');
                    filename = regexprep(filename,'.raw','');
                    filename = regexprep(filename,'.xml','');
                    
                    RAW_path = path;
                    RAW_filename = [filename, '.RAW'];
                    XML_path = path;
                    XML_filename = [filename, '.XML'];
                    SL_path = path;
                    SL_filename = [filename,'.xls'];
                    
                    SAVE_path = path;
                    SAVE_filename = [filename, '.mat'];
                    
                    if ~isempty(data)
                        try
                            validate_spectra();
                        catch err
                            print_code_now(['Error validating spectra: ', err.identifier, '. Please reset.'])
                            set(handle_reset,'Enable','on');
                        end
                        print_now(['Saving...', filename]);
                    end
                    %%%%%% Check Saved Parameters %%%%%%%%%%%%%%%%%
                    % Need to collect and include outpath similar to
                    save( ...
                        [SAVE_path, SAVE_filename], ...
                        'data', 'iTRAQType', 'iTRAQ_masses', 'SILAC', 'SILAC_R6', 'SILAC_R10', 'SILAC_K6', 'SILAC_K8', ...
                        'cont_thresh', 'cont_window', 'HCD_tol', 'CID_tol', 'OUT_path', ...
                        '-v7' ...
                    );
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    print_now('');
                    
                    data = {};
                    init_channels;
                end
            end
            %          end
        end
    end

    %%% Upload file
    function upload(~, ~)
        h2 = figure( ...
            'pos', [400, 400, 500, 200], ...
            'WindowStyle', 'modal' ...
        );
        set(gcf, ...
            'name', 'File Selection', ...
            'numbertitle', 'off', ...
            'MenuBar', 'none' ...
        );
        set(gca, ...
            'Visible', 'off', ...
            'Position', [0, 0, 1, 1] ...
        );
        
        text( ...
            10, 150, 'RAW File:', ...
            'Units', 'pixels' ...
        );
        handle_RAW = uicontrol( ...
            'Style', 'edit', ...
            'Position', [130, 138, 290, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Position', [420, 138, 20, 20], ...
            'String', '...', ...
            'Callback', @select_RAW ...
        );
        
        text( ...
            10, 125, 'Mascot XML:', ...
            'Units', 'pixels' ...
        );
        handle_XML = uicontrol( ...
            'Style', 'edit', ...
            'Position', [130, 113, 290, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Position', [420, 113, 20, 20], ...
            'String', '...', ...
            'Callback', @select_XML ...
        );
        
        text( ...
            10, 100, 'Output Directory:', ...
            'Units', 'pixels' ...
        );
        handle_OUT = uicontrol( ...
            'Style', 'edit', ...
            'Position', [130, 88, 290, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Position', [420, 88, 20, 20], ...
            'String', '...', ...
            'Callback', @select_OUT ...
        );
        
        text( ...
            10, 75, 'Scan List (Optional):', ...
            'Units', 'pixels' ...
        );
        handle_SL = uicontrol( ...
            'Style', 'edit', ...
            'Position', [130, 63, 290, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Position', [420, 63, 20, 20], ...
            'String', '...', ...
            'Callback', @select_SL ...
        );
        
        uicontrol( ...
            'Style', 'pushbutton', ...
            'Position', [300, 33, 100, 20], ...
            'String', 'Process', ...
            'Callback', @call_process ...
        );
        
        function select_RAW(~, ~)
            [RAW_filename, RAW_path] = uigetfile(['*.raw;*.baf'], 'RAW Files');
            set(handle_RAW, 'String', fullfile(RAW_path, RAW_filename));
        end
        
        function select_XML(~, ~)
            [XML_filename, XML_path] = uigetfile([RAW_path, '\*.xml'], 'XML Files');
            set(handle_XML, 'String', fullfile(XML_path, XML_filename));
        end
        
        function select_OUT(~, ~)
            OUT_path = uigetdir(RAW_path);
            OUT_path = [OUT_path, '\'];
            set(handle_OUT, 'String', OUT_path);
        end
        
        function select_SL(~, ~)
            [SL_filename, SL_path] = uigetfile([RAW_path, '\*.xls;*.xlsx'], 'Excel Files (.xls, .xlsx)');
            set(handle_SL, 'String', fullfile(SL_path, SL_filename));
        end
        
        function call_process(~, ~)
            if isempty(RAW_filename)
                msgbox('No RAW file selected', 'Warning');
                return;
            end
            if isempty(XML_filename)
                msgbox('No XML file selected', 'Warning');
                return;
            end
            if isempty(OUT_path)
                msgbox('No output directory selected', 'Warning');
                return;
            end

            close(h2);
            process;
        end
    end
    
    function process(~, ~)
        set(handle_file, 'Enable', 'off');
        set(handle_file_continue, 'Enable', 'off');

        filename = regexprep(RAW_filename, '.RAW', '');
        filename = regexprep(filename, '.raw', '');
        filename = regexprep(filename, '.xml', '');
        filename = regexprep(filename, '.baf', ''); % to support .baf files

        CID_tol = str2double(get(handle_CID_tol, 'String')) / 1e6;
        HCD_tol = str2double(get(handle_HCD_tol, 'String')) / 1e6;

        try
            validate_spectra();
        catch err
            print_code_now(['Error validating spectra: ', err.identifier, '. Please reset.'])
            set(handle_reset, 'Enable', 'on');
        end
        if ~isempty(data)
            [mtree,jtree] = build_tree(filename, data);
            set(handle1, 'Enable', 'off');
            set(handle2, 'Enable', 'off');
            set(handle3, 'Enable', 'off');
            set(handle_export, 'Enable', 'on');
            set(handle_file_save,'Enable', 'on');
            set(handle_reset, 'Enable', 'on');
            set(handle_search, 'Visible', 'on', 'Enable', 'on');
            % set(handle_transfer, 'Visible', 'on', 'Enable', 'on');

            hide_load_settings;
        end
    end
        
    function [labels, masses] = detect_from_itype(itype)
        switch itype{2}
            case 4
                labels = iTRAQ_4_plex_labels;
                masses = iTRAQ_4_plex_masses;
            case 6
                labels = TMT_6_plex_labels;
                masses = TMT_6_plex_masses;
            case 8
                labels = iTRAQ_8_plex_labels;
                masses = iTRAQ_8_plex_masses;
            case 10
                labels = TMT_10_plex_labels;
                masses = TMT_10_plex_masses;
            otherwise
                labels = [];
                masses = [];
        end
    end

    %%% Hide the load / batch-processing settings in the left column
    %%% of the window.
    function hide_load_settings()
        lst_handles = [ ...
            handle_prec_cont, handle_threshold, handle_window, ...
            handle_CID_tol, handle_HCD_tol, ...
            handle_batch_process ...
        ];
        lst_texts = [ ...
            handle_percent_text, handle_mz_text, ...
            handle_HCD_text, handle_CID_text ...
        ];
        
        for i = 1:length(lst_handles)
            set(lst_handles(i), 'Visible', 'off', 'Enable', 'off');
        end
        for i = 1:length(lst_texts)
            delete(lst_texts(i));
        end
    end

    %%% Load Session
    function load_session(~, ~)
        [LOAD_filename, LOAD_path] = uigetfile({'*.mat','MAT Files'});
        run_load_session(LOAD_filename, LOAD_path);
    end

    function run_load_session(LOAD_filename, LOAD_path)
        if exist(fullfile(LOAD_path, LOAD_filename), 'file')
            print_now('Loading...');
            set(handle_file, 'Enable', 'off');
            set(handle_file_continue, 'Enable', 'off');
            
            filename = regexprep(LOAD_filename, '.mat', '');
            
            temp = load(fullfile(LOAD_path, LOAD_filename));
            data = temp.data;
            iTRAQType = temp.iTRAQType;
            % iTRAQ_masses = temp.iTRAQ_masses;
            % Don't save iTRAQ_labels, for backwards compatibility
            [iTRAQ_labels, iTRAQ_masses] = detect_from_itype(iTRAQType);
            SILAC = temp.SILAC;
            SILAC_R6 = temp.SILAC_R6;
            SILAC_R10 = temp.SILAC_R10;
            SILAC_K6 = temp.SILAC_K6;
            SILAC_K8 = temp.SILAC_K8;
            cont_thresh = temp.cont_thresh;
            cont_window = temp.cont_window;
            
            % Checks if an output directory is selected and if a selected
            % output directory is valid. If not, requests an output
            % directory from the user.
            
            if isfield(temp, 'HCD_tol')
                HCD_tol = temp.HCD_tol;
            else
                HCD_tol = 10;
            end
            
            if isfield(temp, 'CID_tol')
                CID_tol = temp.CID_tol;
            else
                CID_tol = 1000;
            end
            
            % Initialize AA masses based on iTRAQ type
            init_fragments_TMT_diox(iTRAQType{2});
            
            [mtree, jtree] = build_tree(filename, data);
            set(handle1, 'Enable', 'off');
            set(handle2, 'Enable', 'off');
            set(handle3, 'Enable', 'off');
            set(handle_export, 'Enable', 'on');
            set(handle_file_save, 'Enable', 'on');
            set(handle_reset, 'Enable', 'on');
            set(handle_search, 'Visible', 'on', 'Enable', 'on');
            % set(handle_transfer, 'Visible', 'on', 'Enable', 'on');
            print_now('');
            
            hide_load_settings;
            
            if ~strcmp(iTRAQType{1},'None')
                set(ax3,'Visible', 'on');
            end
            if isfield(temp, 'OUT_path') && exist(temp.OUT_path, 'dir')
                OUT_path = temp.OUT_path;
            else
                h2 = figure( ...
                    'pos', [400, 400, 500, 200], ...
                    'WindowStyle', 'modal' ...
                );
                set(gcf, ...
                    'name', 'Output Directory', ...
                    'numbertitle', 'off', ...
                    'MenuBar', 'none' ...
                );
                set(gca, ...
                    'Visible', 'off', ...
                    'Position', [0, 0, 1, 1] ...
                );
                
                text( ...
                    10, 150, 'Please select an output diretory.', ...
                    'Units', 'pixels' ...
                );
                text( ...
                    10, 100, 'Output Directory:', ...
                    'Units', 'pixels' ...
                );
                handle_OUT = uicontrol( ...
                    'Style', 'edit', ...
                    'Position', [130, 88, 290, 20], ...
                    'Enable', 'on', ...
                    'HorizontalAlignment', 'left' ...
                );
                uicontrol( ...
                    'Style', 'pushbutton', ...
                    'Position', [420, 88, 20, 20], ...
                    'String', '...', ...
                    'Callback', @select_OUT ...
                );
                
                uicontrol( ...
                    'Style', 'pushbutton', ...
                    'Position', [300, 33, 100, 20], ...
                    'String', 'Continue', ...
                    'Callback', @proceed ...
                );
            end
        end
        
        function select_OUT(~, ~)
            OUT_path = uigetdir(RAW_path);
            OUT_path = [OUT_path, '\'];
            set(handle_OUT, 'String', OUT_path);
        end
        function proceed(~, ~)
            if isempty(OUT_path)
                msgbox('No output directory selected', 'Warning');
            else
                close(h2);
            end
        end
    end

    %%% Save Session
    function save_session(~, ~)
        [SAVE_filename, SAVE_path] = uiputfile({'*.mat','MAT Files'},'Save Session As',[filename,'.mat']);
        run_save_session(SAVE_filename, SAVE_path);
    end

    function run_save_session(SAVE_filename, SAVE_path)
        print_now('Saving...');
        save( ...
            [SAVE_path, SAVE_filename], ...
            'data', ...
            'iTRAQType', 'iTRAQ_masses', 'SILAC', 'SILAC_R6', 'SILAC_R10', 'SILAC_K6', 'SILAC_K8', ...
            'cont_thresh', 'cont_window', 'HCD_tol', 'CID_tol', 'OUT_path', ...
            '-v7' ...
        );
        print_now('');
    end

    %%% Search by scan number or protein name
    function search(~, ~)
        h2 = figure( ...
            'pos',[400, 400, 500, 200], ...
            'WindowStyle', 'modal' ...
        );
        set(gcf, ...
            'name', 'Search', ...
            'numbertitle', 'off', ...
            'MenuBar', 'none' ...
        );
        set(gca, ...
            'Position', [0, 0, 1, 1], ...
            'Visible', 'off' ...
        );
        
        text( ...
            10, 150, 'Protein Name:', ...
            'Units', 'pixels' ...
        );
        handle_search_protein = uicontrol( ...
            'Style', 'edit', ...
            'Position', [100, 138, 200, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        
        text( ...
            10, 125, 'Scan Number:', ...
            'Units', 'pixels' ...
        );
        handle_search_scan_number = uicontrol( ...
            'Style', 'edit', ...
            'Position', [100, 113, 200, 20], ...
            'Enable', 'on', ...
            'HorizontalAlignment', 'left' ...
        );
        
        uicontrol( ...
            'Style', 'pushbutton', ...
            'String', 'Search', ...
            'Position', [25, 10, 50, 20], ...
            'Callback', @SearchCallback ...
        );
        
        function SearchCallback(~, ~)
            prot_name = get(handle_search_protein,'String');
            scan_num = str2num(get(handle_search_scan_number,'String'));
            if ~isempty(prot_name)
                names = {};
                prev_name = '';
                for i = 1:length(data)
                    if ~isempty(regexp(data{i}.protein, prot_name, 'once')) && ~strcmp(data{i}.protein, prev_name)
                        names{end+1} = data{i}.protein;
                        prev_name = data{i}.protein;
                    end
                end
                
                if isempty(names)
                    msgbox('No Matching Proteins','Warning');
                elseif length(names) == 1
                    choose_protein(names{1});
                else
                    % More than one match
                    close(h2);
                    h2 = figure( ...
                        'pos', [400, 400, 500, 200], ...
                        'WindowStyle', 'modal' ...
                    );
                    set(gcf, ...
                        'name', 'Search', ...
                        'numbertitle', 'off', ...
                        'MenuBar', 'none' ...
                    );
                    set(gca, ...
                        'Position', [0, 0, 1, 1], ...
                        'Visible', 'off' ...
                    );
                    text( ...
                        100, 150, 'Protein Name:', ...
                        'Units', 'pixels' ...
                    );
                    
                    handle_select_protein = uicontrol( ...
                        'Style', 'listbox', ...
                        'Position', [100, 38, 200, 100], ...
                        'String', names ...
                    );
                    uicontrol( ...
                        'Style', 'pushbutton', ...
                        'String', 'Select', ...
                        'Position', [100, 10, 50, 20], ...
                        'Callback', @SelectNameCallback ...
                    );
                end
                
            elseif ~isempty(scan_num)
                node = get(mtree.root,'FirstChild');
                found = 0;
                while ~found && ~isempty(node)
                    if get(node,'UserData') == scan_num
                        found = 1;
                    else
                        node = get(node, 'NextNode');
                    end
                end
                if ~found
                    msgbox('No Matching Scans', 'Warning');
                else
                    mtree.setSelectedNode(node);
                    prev_node = '';
                    close(h2);

                    % Move focus in tree to newly selected scan number
                    jtree.grabFocus;
                    tree_row = mtree.Tree.getSelectionRows();
                    %pause(0.1);
                    mtree.Tree.scrollRowToVisible(tree_row);
                    mtree.expand(node);
                    %                 mtree.collapse(node);
                    mtree.FigureComponent.getHorizontalScrollBar.setValue(0);

                    % Redraw new scan information
                    mousePressedCallback();
                end
                
            end
            
            function SelectNameCallback(~, ~)
                all_names = get(handle_select_protein,'String');
                curr_name = all_names{get(handle_select_protein,'Value')};
                choose_protein(curr_name)
            end
            
            function choose_protein(curr_name)
                node = get(mtree.root,'FirstChild');
                while ~strcmp(get(node,'Name'), curr_name)
                    node = get(node,'NextSibling');
                end
                
                mtree.setSelectedNode(node);
                
                prev_node = '';
                close(h2);
                
                % Move focus in tree to newly selection protein
                jtree.grabFocus;
                tree_row = mtree.Tree.getSelectionRows();
                pause(0.1);
                mtree.Tree.scrollRowToVisible(tree_row);
                mtree.expand(node);
                %                 mtree.collapse(node);
                mtree.FigureComponent.getHorizontalScrollBar.setValue(0);
                
                set(handle1, 'Enable', 'off');
                set(handle2, 'Enable', 'off');
                set(handle3, 'Enable', 'off');
                
                % Clear all Plots
                cla(ax1);
                cla(ax1_assign);
                cla(ax1_info);
                cla(ax2);
                if iTRAQType{2} > 0
                    cla(ax3);
                end
                set(ax1, 'TickDir', 'out', 'box', 'off');
                set(ax2, 'TickDir', 'out', 'box', 'off');
                if iTRAQType{2} > 0
                    set(ax3, 'TickDir', 'out', 'box', 'off');
                end
            end
        end
    end

    %%% Transfer choices from another .mat file for same run
    function transfer(~, ~)
        global R K k;
        cd('input');
        [trans_filename, ~] = uigetfile({'*.mat','MAT Files'});
        cd('..');
        if trans_filename
            print_now('Loading...');
            set(handle_file,'Enable', 'off');
            set(handle_file_continue,'Enable', 'off');
            
            trans_filename = regexprep(trans_filename,'.mat','');
            new_data = data;
            temp = load(['input\', trans_filename, '.mat']);
            if (temp.iTRAQType{2} == iTRAQType{2}) && (SILAC_R6 == temp.SILAC_R6) && (SILAC_R10 == temp.SILAC_R10) && (SILAC_K6 == temp.SILAC_K6) && (SILAC_K8 == temp.SILAC_K8)
                if length(new_data) == length(temp.data)
                    print_now('Tranferring...');
                    for i = 1:length(temp.data)
                        if ~isfield(temp.data{i},'code') && isfield(new_data{i},'code')
                            % Scan has been accepted anyway
                            
                            %%% PROCESS ANYWAY %%%
                            % Modify masses of SILAC labeled amino acids for current
                            % peptide
                            
                            if new_data{i}.r6 > 0
                                R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass(6,0,0,0,0,0);
                            elseif new_data{i}.r10 > 0
                                R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass(10,0,0,0,0,0);
                            else
                                R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0);
                            end
                            
                            if new_data{i}.k6 > 0
                                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass(6,0,0,0,0,0);
                                % Acetyl Lysine
                                k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0) + exact_mass(8,0,0,0,0,0);
                            elseif new_data{i}.k8 > 0
                                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass(6,0,0,0,0,0);
                                % Acetyl Lysine
                                k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0) + exact_mass(8,0,0,0,0,0);
                            else
                                % iTRAQ
                                if iTRAQType{2} == 4
                                    iTRAQ = 144.1021 + exact_mass(1,0,0,0,0,0);
                                    K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
                                elseif iTRAQType{2} == 8
                                    iTRAQ = 304.2054 + exact_mass(1,0,0,0,0,0);
                                    K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
                                elseif iTRAQType{2} == 6 || iTRAQType{2} == 10 %***
                                    iTRAQ = 229.1629 + exact_mass(1,0,0,0,0,0);
                                    K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
                                else
                                    K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0);
                                end
                                % Acetyl Lysine, not iTRAQ labeled
                                k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0);
                            end
                            
                            poss_seq = gen_possible_seq2_diox(new_data{i}.pep_seq, new_data{i}.pY, new_data{i}.pSTY, new_data{i}.oM, new_data{i}.doM, new_data{i}.acK);
                            
                            if min(size(poss_seq)) > 0
                                fragments = fragment_masses2_diox(poss_seq, new_data{i}.pep_exp_z, 0);
                                
                                % Include all peaks > 10%
                                temp_peaks = new_data{i}.scan_data(:,2)/max(new_data{i}.scan_data(:,2));
                                temp_peaks = find(temp_peaks > 0.1);
                                
                                % Find peaks that are local maximums in empty regions
                                for k_idx = 1:length(new_data{i}.scan_data(:,2))
                                    idx = find(abs(new_data{i}.scan_data(:,1) - new_data{i}.scan_data(k_idx,1)) < 25);
                                    if new_data{i}.scan_data(k_idx,2) == max(new_data{i}.scan_data(idx,2)) && new_data{i}.scan_data(k_idx,2)/max(new_data{i}.scan_data(:,2)) > 0.025
                                        temp_peaks = [temp_peaks; k_idx];
                                    end
                                end
                                temp_peaks = unique(temp_peaks);
                                
                                for j = 1:max(size(fragments))
                                    fragments{j}.validated = compare_spectra4(fragments{j}, new_data{i}.scan_data(temp_peaks,:), data{i}.pep_exp_z, data{i}.c13num, CID_tol);
                                    fragments{j}.status = 0;
                                end
                                new_data{i}.fragments = fragments;
                                new_data{i} = rmfield(new_data{i},'code');
                            end
                            %%%%%%%%%%%%%%%%%%%%%%
                        end
                        if isfield(temp.data{i},'fragments')
                            for j = 1:length(temp.data{i}.fragments)
                                % Copy choices made for individuals IDs
                                if new_data{i}.fragments{j}.status == 0
                                    new_data{i}.fragments{j}.status = temp.data{i}.fragments{j}.status;
                                end
                            end
                        end
                    end
                    clear data;
                    data = new_data;
                    mtree = 0;
                    jtree = 0;
                    [mtree,jtree] = build_tree(filename, data);
                else
                    msgbox('Files do not match', 'modal')
                end
            else
                msgbox('Files do not match', 'modal')
            end
        end
        clear temp;
        print_now('');
    end

    %%% Display Message Below Plot
    function print_now(string)
        axes(ax0);
        delete(handle_print_now);
        handle_print_now = text( ...
            .25, .85, string, ...
            'Units', 'normalized', ...
            'Interpreter', 'none' ...
        );
        drawnow;
    end

    %%% Display Code Text Above Plot
    function print_code_now(string)
        axes(ax0);
        delete(handle_print_code_now);
        handle_print_code_now = text( ...
            .25, .9, string, ...
            'Units', 'normalized', ...
            'Interpreter', 'none', ...
            'FontWeight', 'bold', ...
            'Color', 'r' ...
        );
        drawnow;
    end
    
    %%% Handle key press events in uitree
    function keyPressedCallback(~, event)
        import java.awt.event.KeyEvent;
        
        switch event.getKeyCode()
            case KeyEvent.VK_A
                accept();
            case KeyEvent.VK_S
                maybe();
            case KeyEvent.VK_D
                reject();
        end
        
        mousePressedCallback();
    end
    
    %%% Handle mouse click events in uitree
    function mousePressedCallback(~, ~)
        
        zoom_is_clicked = 0;
        
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue, '\.', 'split');
        
        % Check if new node selected
        if strcmp(node.getValue, prev_node)
            return
        end
        
        print_code_now('');
        set(handle_process_anyway, ...
            'Visible', 'off', ...
            'Enable', 'off' ...
        );
        
        function clear_plots()
            % Clear all Plots
            cla(ax1);
            cla(ax1_assign);
            cla(ax1_info);
            cla(ax2);
            
            if iTRAQType{2} > 0
                cla(ax3);
            end
        end
        
        function set_ticks()
            set(ax1, 'TickDir', 'out', 'box', 'off');
            set(ax2, 'TickDir', 'out', 'box', 'off');
            
            if iTRAQType{2} > 0
                set(ax3, 'TickDir', 'out', 'box', 'off');
            end
        end
        
        function display_labels()
            axes(ax1_info);
            text(0.01, 0.95, ['Scan Number: ', num2str(data{str2num(scan_curr{1})}.scan_number)]);
            text(0.01, 0.90, ['MASCOT Score: ', num2str(round(data{str2num(scan_curr{1})}.pep_score))]);

            axes(ax2);
            plot_prec(str2num(scan_curr{1}));
            text(.5, 1.1, 'Precursor', 'HorizontalAlignment', 'center');

            if iTRAQType{2} > 0
                axes(ax3);
                plot_iTRAQ(str2num(scan_curr{1}));
                text(.5, 1.1, 'iTRAQ', 'HorizontalAlignment', 'center');
            end
        end
        
        if get(node, 'Root') || ~isempty(regexp(node.getValue, 'protein', 'once'))
            % Root or Protein node selected
            set(handle1, 'Enable', 'off');
            set(handle2, 'Enable', 'off');
            set(handle3, 'Enable', 'off');
            set(handle_RR, 'Enable', 'off'); % Turned selection for roots off

            clear_plots();
            set_ticks();
        elseif check_node_is_assignment(node)
            % Particular Peptide Assignment Selected
            set(handle1, 'Enable', 'on');
            set(handle2, 'Enable', 'on');
            set(handle3, 'Enable', 'on');
            set(handle_RR, 'Enable', 'on');

            % Replot new scan and assignment
            clear_plots();

            if is_zoomed == 1
                % Find indicies of start and end of user selected zoom
                % window
                x1 = find(data{str2num(scan_curr{1})}.scan_data(:,1) > hold_zoom_start);
                x2 = find(data{str2num(scan_curr{1})}.scan_data(:,1) < hold_zoom_end);

                x_used = intersect(x1,x2);

                % Find the X, Y data to be displayed
                X = data{str2num(scan_curr{1})}.scan_data(x_used, 1);
                Y = data{str2num(scan_curr{1})}.scan_data(x_used, 2);
                
                % Scale x-axis for zoomed window
                set(ax1, 'XLim', [hold_zoom_start, hold_zoom_end]);
            else
                X = data{str2num(scan_curr{1})}.scan_data(:,1);
                Y = data{str2num(scan_curr{1})}.scan_data(:,2);
            end
            
            axes(ax1)
            stem(X, Y, 'Marker', 'none');
            ylim([0, 1.25 * max(Y)]);

            axes(ax1_assign)
            display_ladder(str2num(scan_curr{1}), str2num(scan_curr{2}));
            plot_assignment(str2num(scan_curr{1}), str2num(scan_curr{2}));
            
            display_labels();

            set(ax1, 'ButtonDownFcn', @zoom_MS2);
            set_ticks();
            %-------------------------------------------------------------------------%
        else
            % Scan Selected
            set(handle1, 'Enable', 'off');
            set(handle2, 'Enable', 'off');
            set(handle3, 'Enable', 'off');

            clear_plots();

            X = data{str2num(scan_curr{1})}.scan_data(:, 1);
            Y = data{str2num(scan_curr{1})}.scan_data(:, 2);
            
            axes(ax1);
            stem(X, Y, 'Marker', 'none');
            ylim([0, 1.25 * max(Y)]);

            display_labels();
            
            if isfield(data{str2num(scan_curr{1})}, 'code') && ...
                    ~strcmp(data{str2num(scan_curr{1})}, 'No Possible Sequence')
                axes(ax1_assign);
                print_code_now(data{str2num(scan_curr{1})}.code);
                
                %%%%%%%%%%%%
                % Only allow the option to reprocess if no unsupported
                % modifications are found
                if isempty(regexp(data{str2num(scan_curr{1})}.code, 'Unsupported Modification', 'once')) && ...
                        isempty(regexp(data{str2num(scan_curr{1})}.code, 'No Possible Sequence', 'once'))
                    set(handle_process_anyway, ...
                        'Enable', 'on', ...
                        'Visible', 'on' ...
                    );
                end
                %%%%%%%%%%%%
            end
            
            set_ticks();
        end
        
        prev_node = node.getValue; %workhere
    end

    %%% Handle mouse click on peak label
    function labelCallback(a,~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue,'\.','split');
        scan = str2num(scan_curr{1});
        id = str2num(scan_curr{2});
        
        [r,~] = size(data{scan}.fragments{id}.validated);
        curr_name = get(a,'String');
        curr_name = strtrim(curr_name); % Remove initial space inserted for cosmetic display
        curr_pos = get(a,'Position');
        curr_ion = 0;
        for i = 1:r
            if strcmp(curr_name, data{scan}.fragments{id}.validated(i, 2)) && curr_pos(1) == data{scan}.fragments{id}.validated{i,1}
                curr_ion = i;
            elseif strcmp(curr_name,data{scan}.fragments{id}.validated(i,2))
                1;
            end
        end
        
        h2 = figure('pos',[300,300,500,500], 'WindowStyle', 'modal');
        set(gcf,'name','Rename Labeled Peak','numbertitle','off', 'MenuBar', 'none');
        set(gca,'Position', [0,0,1,1], 'Visible', 'off');
        text(.1,.98,['Observed Mass: ', num2str(data{scan}.fragments{id}.validated{curr_ion,1})]);
        text(.1,.94,['Current Label: ', get(a,'String')]);
        
        %         uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [25 10 50 20],'Callback', @OKCallback);
        %         uicontrol('Style', 'pushbutton', 'String', 'Cancel','Position', [75 10 50 20],'Callback', @CancelCallback);
        
        rbh = uibuttongroup('Position',[0,0,0.5,0.9],'SelectionChangeFcn', @radioCallback);
        
        [r,~] = size(data{scan}.fragments{id}.validated{curr_ion,6});
        text(280,450,'Mass:','Units','pixels');
        
        if r > 0
            for i = 1:r
                % Show Radio Button with Name
                temp_h = uicontrol('Style','Radio','String', data{scan}.fragments{id}.validated{curr_ion,6}{i,1},'Parent', rbh, 'Position', [20 400 - (i-1)*50 150 20]);
                % Show Mass
                text(280, 410 - (i-1)*50, num2str(data{scan}.fragments{id}.validated{curr_ion,6}{i,3}),'Units','pixels');
            end
            uicontrol('Style','Radio','String', 'Other:','Parent', rbh, 'Position', [20 400 - r*50 200 20]);
            handle_other = uicontrol('Style','edit','Position',[50,400-r*50-20,150,20],'Enable','off');
            uicontrol('Style','Radio','String', 'None','Parent', rbh, 'Position', [20 400 - (r + 1)*50 200 20]);
        else
            uicontrol('Style','Radio','String', 'Other:','Parent', rbh, 'Position', [20 400 - r*50 200 20]);
            handle_other = uicontrol('Style','edit','Position',[50,400-r*50-20,150,20],'Enable','on');
        end
        
        uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [25 10 50 20],'Callback', @OKCallback);
        uicontrol('Style', 'pushbutton', 'String', 'Cancel','Position', [75 10 50 20],'Callback', @CancelCallback);
        
        function radioCallback(a,~)
            if strcmp(get(get(a,'SelectedObject'),'String'),'Other:')
                set(handle_other,'Enable','on');
            else
                set(handle_other,'Enable','off');
            end
        end
        
        function OKCallback(~, ~)
            if strcmp(get(get(rbh,'SelectedObject'),'String'),'Other:')
                if ~isempty(get(handle_other,'String'))
                    data{scan}.fragments{id}.validated{curr_ion,2} = get(handle_other,'String');
                    data{scan}.fragments{id}.validated{curr_ion,3} = 'unknown';
                    data{scan}.fragments{id}.validated{curr_ion,5} = 'unknown';
                else
                    if isempty(data{scan}.fragments{id}.validated{curr_ion,6})
                        data{scan}.fragments{id}.validated{curr_ion,2} = [];
                        data{scan}.fragments{id}.validated{curr_ion,3} = [];
                        data{scan}.fragments{id}.validated{curr_ion,5} = [];
                    end
                end
            elseif strcmp(get(get(rbh,'SelectedObject'),'String'),'None')
                data{scan}.fragments{id}.validated{curr_ion,2} = [];
                data{scan}.fragments{id}.validated{curr_ion,3} = [];
                data{scan}.fragments{id}.validated{curr_ion,5} = [];
            else
                name = get(get(rbh,'SelectedObject'),'String');
                data{scan}.fragments{id}.validated{curr_ion,2} = name;
                
                [r,~] = size(data{scan}.fragments{id}.validated{curr_ion,6});
                chosen_id = 0;
                for i = 1:r
                    if strcmp(data{scan}.fragments{id}.validated{curr_ion,6}{i,1},name)
                        chosen_id = i;
                    end
                end
                data{scan}.fragments{id}.validated{curr_ion,3} = data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3};
                data{scan}.fragments{id}.validated{curr_ion,5} = abs(data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3}-data{scan}.fragments{id}.validated{curr_ion,1})/data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3};
            end
            cla(ax1_assign);
            axes(ax1_assign);
            display_ladder(scan, id);
            plot_assignment(scan, id);
            close(h2);
        end
        function CancelCallback(~, ~)
            close(h2);
        end
    end

    %%% Read MASCOT output XML file
    function validate_spectra()
        % Check if precursor contamination exclusion has been activated
        if get(handle_prec_cont, 'Value')
            % Get new contamination threshold, default = 100%
            if ~isempty(get(handle_threshold, 'String'))
                cont_thresh = str2num(get(handle_threshold, 'String'));
            end
            % Get new contamination window, default = 1 m/z
            if ~isempty(get(handle_window, 'String'))
                cont_window = str2num(get(handle_window, 'String'));
            end
        end
        
        temp_path = fullfile(OUT_path, filename);
        if exist(temp_path, 'dir') == 0
            mkdir(temp_path);
        end
        print_now(['Reading File: ', filename]);
        
        try
            [mods, it_mods, data] = read_mascot_xml2_baf(fullfile(XML_path, XML_filename));
        catch err
            print_now('');
            msgbox(['Improperly Formatted XML File:\n', err.identifier, fullfile(XML_path, XML_filename)],'Warning');
            return;
        end
        
        % disp(['Size of Data: ', num2str(length(data))]);
        
        % Get information about fixed and variable modifications
        C_carb = false;
        iTRAQType = {'None', 0};
        
        M_Ox = false;
        M_Diox = false;
        Y_p = false;
        ST_p = false;
        K_ac = false;
        
        % Include constant modifications***
        for i = 1:length(mods)
            if strcmp(mods{i}, 'Carbamidomethyl (C)')
                C_carb = true;
            elseif ~isempty(strfind(mods{i}, 'iTRAQ')) || ~isempty(strfind(mods{i}, 'TMT'))
                if strcmp(mods{i},'iTRAQ8plex (K)') || strcmp(mods{i},'iTRAQ8plex (N-term)')
                    iTRAQType = {'Fixed', 8};
                    iTRAQ_masses = iTRAQ_8_plex_masses;
                    iTRAQ_labels = iTRAQ_8_plex_labels;
                elseif strcmp(mods{i},'iTRAQ4plex (K)') || strcmp(mods{i},'iTRAQ4plex (N-term)')
                    iTRAQType = {'Fixed', 4};
                    iTRAQ_masses = iTRAQ_4_plex_masses;
                    iTRAQ_labels = iTRAQ_4_plex_labels;
                elseif strcmp(mods{i},'TMT10plex (K)') || strcmp(mods{i},'TMT10plex (N-term)')
                    iTRAQType = {'Fixed', 10};
                    iTRAQ_masses = TMT_10_plex_masses;
                    iTRAQ_labels = TMT_10_plex_labels;
                elseif strcmp(mods{i},'TMT6plex (K)') || strcmp(mods{i},'TMT6plex (N-term)')
                    iTRAQType = {'Fixed', 6};
                    iTRAQ_masses = TMT_6_plex_masses;
                    iTRAQ_labels = TMT_6_plex_labels;
                end
            end
        end
        
        % Include variable modifications***
        for i = 1:length(it_mods)
            if strcmp(it_mods{i}, 'Oxidation (M)')
                M_Ox = true;
            elseif strcmp(it_mods{i}, 'Dioxidation (M)')
                M_Diox = true;
            elseif strcmp(it_mods{i}, 'Phospho (Y)')
                Y_p = true;
            elseif strcmp(it_mods{i}, 'Phospho (ST)') || strcmp(it_mods{i}, 'Phospho (STY)')
                Y_p = true;
                ST_p = true;
            elseif strcmp(it_mods{i}, 'Acetyl (K)')
                acK = true;
            elseif strcmp(it_mods{i},'iTRAQ8plex (K)') || strcmp(it_mods{i},'iTRAQ8plex (N-term)')
                iTRAQType = {'Variable', 8};
                iTRAQ_masses = iTRAQ_8_plex_masses;
                iTRAQ_labels = iTRAQ_8_plex_labels;
            elseif strcmp(it_mods{i},'iTRAQ4plex (K)') || strcmp(it_mods{i},'iTRAQ4plex (N-term)')
                iTRAQType = {'Variable', 4};
                iTRAQ_masses = iTRAQ_4_plex_masses;
                iTRAQ_labels = iTRAQ_4_plex_labels;
            elseif strcmp(it_mods{i},'TMT10plex (K)') || strcmp(it_mods{i},'TMT10plex (N-term)')
                iTRAQType = {'Variable', 10};
                iTRAQ_masses = TMT_10_plex_masses;
                iTRAQ_labels = TMT_10_plex_labels;
                
            elseif strcmp(it_mods{i},'TMT6plex (K)') || strcmp(it_mods{i},'TMT6plex (N-term)')
                iTRAQType = {'Variable', 6};
                iTRAQ_masses = TMT_6_plex_masses;
                iTRAQ_labels = TMT_6_plex_labels;
                
            elseif strcmp(it_mods{i},'Arginine-13C6 (R-13C6) (R)') || strcmp(it_mods{i}, 'SILAC: 13C(6) (R)') || ...
                    (~isempty(regexp(it_mods{i}, '13C\(6\)')) && ~isempty(regexp(it_mods{i}, '\(R\)')))
                SILAC = 1;
                SILAC_R6 = 1;
            elseif strcmp(it_mods{i},'Arginine-13C615N4 (R-full) (R)') || strcmp(it_mods{i}, 'SILAC: 13C(6)15N(4) (R)') || ...
                    (~isempty(regexp(it_mods{i}, '13C\(6\)15N\(4\)')) && ~isempty(regexp(it_mods{i}, '\(R\)')))
                SILAC = 1;
                SILAC_R10 = 1;
            elseif strcmp(it_mods{i},'Lysine-13C6 (K-13C6) (K)') || strcmp(it_mods{i}, 'SILAC: 13C(6) (K)') || ...
                    (~isempty(regexp(it_mods{i}, '13C\(6\)')) && ~isempty(regexp(it_mods{i}, '\(K\)')))
                SILAC = 1;
                SILAC_K6 = 1;
            elseif strcmp(it_mods{i},'Lysine-13C615N2 (K-full) (K)') || strcmp(it_mods{i}, 'SILAC: 13C(6)15N(2) (K)') || ...
                    (~isempty(regexp(it_mods{i}, '13C\(6\)15N\(2\)')) && ~isempty(regexp(it_mods{i}, '\(K\)')))
                SILAC = 1;
                SILAC_K8 = 1;
            elseif strcmp(it_mods{i},'SILAC: 13C(6)+Acetyl (K)')
                acK = true;
                SILAC = 1;
                SILAC_K6 = 1;
            elseif strcmp(it_mods{i},'SILAC: 13C(6)15N(2)+Acetyl (K)')
                acK = true;
                SILAC = 1;
                SILAC_K8 = 1;
            end
        end
        
        % %         %------------------------------------%
        % %         % Remove scans without iTRAQ
        % %         if strcmp(iTRAQType{1},'Variable')
        % %             for i = length(data):-1:1
        % %                 if isfield(data{i},'pep_var_mods');
        % %                     [a,~] = size(data{i}.pep_var_mods);
        % %                     has_iTRAQ = 0;
        % %                     for j = 1:a
        % %                         b = regexp(data{i}.pep_var_mods{j,2},'iTRAQ');
        % %                         if length(b) > 0
        % %                             has_iTRAQ = 1;
        % %                         end
        % %                     end
        % %                     if ~has_iTRAQ
        % %                         if ~isfield(data{i},'code')
        % %                             data{i}.code = 'no iTRAQ';
        % %                         else
        % %                             data{i}.code = [data{i}.code, ' + no iTRAQ'];
        % %                         end
        % %                         disp('No iTRAQ');
        % %                     end
        % %                 else
        % %                     if ~isfield(data{i},'code')
        % %                         data{i}.code = 'no iTRAQ';
        % %                     else
        % %                         data{i}.code = [data{i}.code, ' + no iTRAQ'];
        % %                     end
        % %                     disp('No iTRAQ');
        % %                 end
        % %             end
        % %         end
        % %         %------------------------------------%
        
        disp(['Line 2022 - Size of Data: ', num2str(length(data))]);
        %------------------------------------%
        %------------------------------------%
        % Remove peptides with too many possible combinations of
        % modifications
        for i = length(data):-1:1
            if isfield(data{i}, 'pep_var_mods')
                [a,~] = size(data{i}.pep_var_mods);
                pY = 0;
                pSTY = 0;
                oM = 0;
                doM = 0;
                acK = 0;
                
                for j = 1:a
                    if strcmp(data{i}.pep_var_mods{j,2},'Phospho (STY)')
                        pSTY = pSTY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(data{i}.pep_var_mods{j,2},'Phospho (ST)')
                        pSTY = pSTY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(data{i}.pep_var_mods{j,2},'Phospho (Y)')
                        pY = pY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(data{i}.pep_var_mods{j,2},'Oxidation (M)')
                        oM = oM + data{i}.pep_var_mods{j,1};
                    elseif strcmp(data{i}.pep_var_mods{j,2},'Dioxidation (M)')
                        doM = doM + data{i}.pep_var_mods{j,1};
                        %                     elseif strcmp(data{i}.pep_var_mods{j,2},'Acetyl (K)')
                        %                         acK = acK + data{i}.pep_var_mods{j,1};
                    end
                end
                
                pep_seq = data{i}.pep_seq;
                num_comb = 1;
                
                if pY > 0
                    num_comb = num_comb*nchoosek(length(regexp(pep_seq,'Y')),pY);
                end
                if pSTY > 0
                    num_comb = num_comb*nchoosek(length(regexp(pep_seq,'[STY]')),pSTY);
                end
                if oM > 0 || doM > 0
                    num_comb = num_comb*nchoosek(length(regexp(pep_seq,'M')),oM)*nchoosek(length(regexp(pep_seq,'M'))-oM,doM);
                end
                data{i}.num_comb = num_comb;
                
                % Remove if too many combinations
                if num_comb > 10
                    if ~isfield(data{i},'code')
                        data{i}.code = ['Too Many Combinations: ', num2str(num_comb)];
                    else
                        data{i}.code = [data{i}.code, ' + Too Many Combinations: ', num2str(num_comb)];
                    end
                    disp('Too Many Combinations');
                end
            else
                data{i}.num_comb = 1;
            end
        end
        
        disp(['Line 2080 - Size of Data: ', num2str(length(data))]);
        %------------------------------------%
        % Initialize AA masses based on iTRAQ type
        init_fragments_TMT_diox(iTRAQType{2});
        
        % Get scan data from RAW file
        scans_used = [];
        if ~isempty(SL_filename)
            if exist(fullfile(SL_path, SL_filename), 'file')
                % Read only fron scan input list
                temp = unique(xlsread(fullfile(SL_path, SL_filename)));
                
                total_found = 0;
                for i = 1:length(temp)
                    j = 1;
                    found = 0;
                    while j <= length(data) && ~found
                        if temp(i) == data{j}.scan_number
                            data{j}.used = 1;
                            found = 1;
                            total_found = total_found + 1;
                        end
                        j = j + 1;
                    end
                end
                disp(['Targets Found: ', num2str(total_found), '/', num2str(length(temp))]);
                
                for i = length(data):-1:1
                    if ~isfield(data{i},'used')
                        data(i) = [];
                    end
                end
            else
                msgbox('No Scan List File Found', 'Warning');
            end
        end
        
        for i = 1:length(data)
            scans_used = [scans_used, data{i}.scan_number];
        end
        
        scans_used = unique(scans_used);
        
        %% Get MS2 Data
        print_now('Getting MS2 Data');
        fid = fopen('config.txt','w');
        scans = [];
        fwrite(fid,'filter="scanNumber');
        
        scan_num = [];
        for i = 1: length(scans_used)
            scans = [scans, ' ', num2str(scans_used(i))];
            scan_num(end+1) = scans_used(i);
        end
        scans = [scans, '"'];
        fwrite(fid,scans);
        fclose(fid);
        
        [a,b] = systemsafe( ...
            msconvert_full_path, ...
            fullfile(RAW_path, RAW_filename), ...
            '-o', RAW_path, ...
            '--outfile', filename, ...
            '--mzXML', '-c', 'config.txt' ...
        );
        % for some reason, .baf file generates a .mzXML file named after
        % the immediate subfolder, not the raw file.
        
        
        
        if a > 0
            warndlg(b,'msConvert Error');
        end
        tic
        
        [a,b] = systemsafe( ...
            msconvert_full_path, ...
            fullfile(RAW_path, RAW_filename), ...
            '-o', RAW_path, ...
            '--outfile', filename, ...
            '--text', '-c', 'config.txt' ...
        );
        
        if a > 0
            warndlg(b,'msConvert Error');
        end
        
        
        isolationMz = msconverttxtread(fullfile(RAW_path, [filename, '.txt']));
        toc
        mzXML_out = mzxmlread2(fullfile(RAW_path, [filename, '.mzXML']));
        
        delete('config.txt');
        %delete([RAW_path, filename,'.txt'])
        iTRAQ_scans_used = [];
        prec_scans_used = [];
        
        if ~isempty(mzXML_out.scan(1).precursorMz.windowWideness)
            cont_window = mzXML_out.scan(1).precursorMz.windowWideness/2; % ^^^
        end
        
        print_now('Storing MS2 Data');
        
        % Transfer MS2 information to data struct
        for i = length(data):-1:1
            idx = find(scans_used == data{i}.scan_number);
            idx2 = find(isolationMz(:,1) == data{i}.scan_number);
            if ~isempty(idx)
                
                data{i}.activation_method = mzXML_out.scan(idx).precursorMz.activationMethod;
                data{i}.prec_scan = mzXML_out.scan(idx).precursorMz.precursorScanNum;
                
                % Now determines if fragmented peak is C13 or C12.  This is
                % a new issue with the QE+ because the isolation window is
                % +/- 0.2 Da instead of 1 Da.
                data{i}.pep_exp_mz_old = data{i}.pep_exp_mz;
                data{i}.pep_exp_mz = isolationMz(idx2,2);
                mzdelta = abs(data{i}.pep_exp_mz - data{i}.pep_exp_mz_old);
                data{i}.c13num = round(mzdelta * data{i}.pep_exp_z);
                
                % If a precursor scan is available
                if ~isempty(mzXML_out.scan(idx).precursorMz.precursorScanNum)
                    prec_scans_used(end+1) = mzXML_out.scan(idx).precursorMz.precursorScanNum;
                    if strcmp(data{i}.activation_method,'CID')
                        data{i}.scan_data = [mzXML_out.scan(idx).peaks.mz(1:2:end),mzXML_out.scan(idx).peaks.mz(2:2:end)];
                        data{i}.scan_type = 'CID';
                        
                        % Record scan number for iTRAQ
                        if ~strcmp(iTRAQType{1},'None')
                            data{i}.iTRAQ_scan = data{i}.scan_number - 1;
                            iTRAQ_scans_used(end+1) = data{i}.scan_number - 1;
                        end
                    else
                        % Resolve HCD data
                        temp1 = mzXML_out.scan(idx).peaks.mz(1:2:end);
                        temp2 = mzXML_out.scan(idx).peaks.mz(2:2:end);
                        if ~issorted(temp1)
                            [temp1,idx] = unique(temp1);
                            temp2 = temp2(idx);
                        end
                        data{i}.scan_data = mspeaks(temp1, temp2);
                        data{i}.scan_type = 'HCD';
                        
                        % Record scan number for iTRAQ
                        if ~strcmp(iTRAQType{1},'None')
                            data{i}.iTRAQ_scan = data{i}.scan_number;
                            iTRAQ_scans_used(end+1) = data{i}.scan_number;
                        end
                    end
                else
                    if ~isfield(data{i},'code')
                        data{i}.code = 'No Precursor Scan Number';
                    else
                        data{i}.code = [data{i}.code,' + No Precursor Scan Number'];
                    end
                    disp('No Precursor Scan Number');
                end
            else
                if ~isfield(data{i},'code')
                    data{i}.code = 'No Matching Query';
                else
                    data{i}.code = [data{i}.code, ' + No Matching Query'];
                end
                disp('No Matching Query');
            end
        end
        
        %-------------------------------------------------------------------------%
        %% Get iTRAQ data
        if ~strcmp(iTRAQType{1},'None')
            % iTRAQ Window
            ax3 = axes('Position', [.84,.125,.14,.25], 'TickDir', 'out', 'box', 'off');
            text(.5,1.1,'iTRAQ', 'HorizontalAlignment', 'center');
            
            
            print_now('Getting iTRAQ Data');
            iTRAQ_scans_used = unique(iTRAQ_scans_used);
            
            fid = fopen('config.txt','w');
            scans = [];
            
            if iTRAQType{2} == 4
                fprintf(fid,'filter="mzWindow [113,118]"\n');
            elseif iTRAQType{2} == 8
                fprintf(fid,'filter="mzWindow [112,122]"\n');
            elseif (iTRAQType{2} == 10 || iTRAQType{2} == 6) %***
                fprintf(fid,'filter="mzWindow [125,132]"\n');
            end
            
            fwrite(fid,'filter="scanNumber');
            
            for i = 1: length(iTRAQ_scans_used)
                scans = [scans, ' ', num2str(iTRAQ_scans_used(i))];
            end
            scans = [scans, '"'];
            fwrite(fid,scans);
            fclose(fid);
            
            
            [a,b] = systemsafe( ...
                msconvert_full_path, ...
                fullfile(RAW_path, RAW_filename), ...
                '-o', RAW_path, ...
                '--outfile', filename, ...
                '--mzXML', '-c', 'config.txt' ...
            );
            
            if a > 0
                warndlg(b,'msConvert Error');
            end
            
            mzXML_out = mzxmlread2(fullfile(RAW_path, [filename, '.mzXML']));
            %             systemsafe('ProteoWizard\"ProteoWizard 3.0.4323"\msconvert input\', filename, '.raw', -o', 'input\', '--mzXML', '-c', 'config.txt');
            %             mzXML_out = mzxmlread2(['input\', filename,'.mzXML']);
            delete('config.txt');
            
            print_now('Storing iTRAQ Data');
            
            for i = 1:length(data)
                idx = find(iTRAQ_scans_used == data{i}.iTRAQ_scan);
                if ~isempty(idx)
                    % Resolve HCD data
                    if length(mzXML_out.scan(idx).peaks.mz) > 0
                        temp1 = mzXML_out.scan(idx).peaks.mz(1:2:end);
                        temp2 = mzXML_out.scan(idx).peaks.mz(2:2:end);
                        if ~issorted(temp1)
                            [temp1,idx] = unique(temp1);
                            temp2 = temp2(idx);
                        end
                        data{i}.iTRAQ_scan_data = mspeaks(temp1, temp2);
                    else
                        data{i}.iTRAQ_scan_data = [];
                    end
                end
            end
        end
        %-------------------------------------------------------------------------%
        %% Determine SILAC precursor masses
        
        for i = 1:length(data)
            num_k = length(regexp(data{i}.pep_seq,'[Kk]'));
            num_r = length(regexp(data{i}.pep_seq,'[Rr]'));
            temp_prec = [];
            pSTY = 0;
            pY = 0;
            oM = 0;
            doM = 0;
            acK = 0;
            r6 = 0;
            r10 = 0;
            k6 = 0;
            k8 = 0;
            
            if isfield(data{i}, 'pep_var_mods')
                [a,~] = size(data{i}.pep_var_mods);
                for j = 1:a
                    curr_var_mod = data{i}.pep_var_mods{j,2};
                    if strcmp(curr_var_mod,'Phospho (STY)')
                        pSTY = pSTY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Phospho (ST)')
                        pSTY = pSTY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Phospho (Y)')
                        pY = pY + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Oxidation (M)')
                        oM = oM + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Dioxidation (M)')
                        doM = doM + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Acetyl (K)')
                        acK = acK + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Arginine-13C6 (R-13C6) (R)') || strcmp(curr_var_mod,'SILAC: 13C(6) (R)') || strcmp(curr_var_mod,'Label:13C(6) (R)')
                        r6 = r6 + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Arginine-13C615N4 (R-full) (R)') || strcmp(curr_var_mod,'SILAC: 13C(6)15N(4) (R)') || strcmp(curr_var_mod,'Label:13C(6)15N(4) (R)')
                        r10 = r10 + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Lysine-13C6 (K-13C6) (K)') || strcmp(curr_var_mod,'SILAC: 13C(6) (K)') || strcmp(curr_var_mod,'Label:13C(6) (K)')
                        k6 = k6 + data{i}.pep_var_mods{j,1};
                    elseif strcmp(curr_var_mod,'Lysine-13C615N2 (K-full) (K)') || strcmp(curr_var_mod,'SILAC: 13C(6)15N(2) (K)') || strcmp(curr_var_mod,'Label:13C(6)15N(2) (K)')
                        k8 = k8 + data{i}.pep_var_mods{j,1};
                        
                    elseif strcmp(curr_var_mod,'SILAC: 13C(6)15N(2)+Acetyl (K)')
                        k8 = k8 + data{i}.pep_var_mods{j,1};
                        acK = acK + data{i}.pep_var_mods{j,1};
                    else
                        if ~isfield(data{i},'code')
                            data{i}.code = ['Unsupported Modification: ', curr_var_mod];
                        else
                            data{i}.code = [data{i}.code, ' + Unsupported Modification: ', curr_var_mod];
                        end
                        disp(['Unsupported Modification: ', curr_var_mod]);
                    end
                end
            end
            data{i}.r6 = r6;
            data{i}.r10 = r10;
            data{i}.k6 = k6;
            data{i}.k8 = k8;
            data{i}.pSTY = pSTY;
            data{i}.pY = pY;
            data{i}.oM = oM;
            data{i}.doM = doM;
            data{i}.acK = acK;
            
            if (r6 > 0 && r10 > 0) || (r6 > 0 && k8 > 0) || (k6 > 0 && k8 > 0) || (k6 > 0 && r10 > 0)
                % Mix of Medium and Heavy SILAC assigned in same
                % assignemnt
                if ~isfield(data{i},'code')
                    data{i}.code = 'Mixed SILAC';
                else
                    data{i}.code = [data{i}.code, ' + Mixed SILAC'];
                end
            elseif ((r6 > 0 || k6 > 0) && (r6 < num_r || k6 < num_k)) || ((r10 > 0 || k8 > 0) && (r10 < num_r || k8 < num_k))
                % Mix of SILAC and non-SILAC in same assignment
                if ~isfield(data{i},'code')
                    data{i}.code = 'Mixed SILAC';
                else
                    data{i}.code = [data{i}.code, ' + Mixed SILAC'];
                end
            end
            %             temp_prec(1) = data{i}.pep_exp_mz - (r6*exact_mass(6,0,0,0,0,0) + ...
            %                 r10*exact_mass(10,0,0,0,0,0) + ...
            %                 k6*exact_mass(6,0,0,0,0,0) + ...
            %                 k8*exact_mass(8,0,0,0,0,0)) / data{i}.pep_exp_z;
            %             temp_prec(2) = temp_prec(1) + (num_r*exact_mass(6,0,0,0,0,0) + num_k*exact_mass(6,0,0,0,0,0))/data{i}.pep_exp_z;
            %             temp_prec(3) = temp_prec(1) + (num_r*exact_mass(10,0,0,0,0,0) + num_k*exact_mass(8,0,0,0,0,0))/data{i}.pep_exp_z;
            
            %%%%%% IMPROVED MASS ACCURACY %%%%%%%%%%%%%
            temp_prec(1) = data{i}.pep_exp_mz - ...
                (r6 * exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0) + ...
                r10 * exact_mass2([0 0],[-6 6],[-4 4],[0 0 0],[0 0 0 0],0) + ...
                k6 * exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0) + ...
                k8 * exact_mass2([0 0],[-6 6],[-2 2],[0 0 0],[0 0 0 0],0)) / data{i}.pep_exp_z;
            
            temp_prec(2) = temp_prec(1) + ...
                (num_r * exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0) + ...
                num_k * exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0))/data{i}.pep_exp_z;
            
            temp_prec(3) = temp_prec(1) + ...
                (num_r * exact_mass2([0 0],[-6 6],[-4 4],[0 0 0],[0 0 0 0],0) + ...
                num_k * exact_mass2([0 0],[-6 6],[-2 2],[0 0 0],[0 0 0 0],0))/data{i}.pep_exp_z;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            data{i}.SILAC_prec = temp_prec;
        end
        
        %% Get Precursor Scan information
        print_now('Getting Precursor Data');
        prec_scans_used = unique(prec_scans_used);
        
        fid = fopen('config.txt','w');
        scans = [];
        
        fwrite(fid,'filter="scanNumber');
        
        for i = 1: length(prec_scans_used)
            scans = [scans, ' ', num2str(prec_scans_used(i))];
        end
        scans = [scans, '"'];
        fwrite(fid,scans);
        fclose(fid);
        
        [a,b] = systemsafe( ...
            msconvert_full_path, ...
            fullfile(RAW_path, RAW_filename), ...
            '-o', RAW_path, ...
            '--outfile', filename, ...
            '--mzXML', '-c', 'config.txt' ...
        );
        
        if a > 0
            warndlg(b,'msConvert Error');
        end
        
        mzXML_out = mzxmlread2(fullfile(RAW_path, [filename, '.mzXML'])); %&&&
        %         systemsafe(['ProteoWizard\"ProteoWizard 3.0.4323"\msconvert input\', filename, '.raw -o input\ --mzXML -c config.txt']);
        %         mzXML_out = mzxmlread2(['input\', filename,'.mzXML']);
        delete('config.txt');
        
        print_now('Storing Precursor Data');
        
        for i = length(data):-1:1
            %             print_now(['Spectra Remaining: ',num2str(i)]);
            idx = find(prec_scans_used == data{i}.prec_scan);
            if ~isempty(idx)
                % Resolve HCD data
                temp1 = mzXML_out.scan(idx).peaks.mz(1:2:end);
                temp2 = mzXML_out.scan(idx).peaks.mz(2:2:end);
                
                if SILAC
                    % Collect MS1 scan data to accomodate SILAC precursors
                    idx2 = intersect(find(temp1 > data{i}.SILAC_prec(1) - 2),find(temp1 < data{i}.SILAC_prec(3) + 2));
                else
                    % Collect MS1 scan data within 2 m/z units of precursor
                    idx2 = find(abs(temp1 - data{i}.pep_exp_mz) < 2);
                end
                
                temp1 = temp1(idx2);
                temp2 = temp2(idx2);
                
                if ~issorted(temp1)
                    [temp1,idx3] = unique(temp1);
                    temp2 = temp2(idx3);
                end
                if max(size(temp1)) > 2
                    data{i}.prec_scan_data = mspeaks(temp1, temp2);
                else
                    if ~isfield(data{i},'code')
                        data{i}.code = 'Poor MS1 data';
                    else
                        data{i}.code = [data{i}.code, ' + Poor MS1 data'];
                    end
                    disp('Poor MS1 data');
                end
            end
        end
        
        %-------------------------------------------------------------------------%
        
        % Remove precursor contaminated scans from validation list
        print_now('Removing Precursor Contaminated Spectra');
        size(data);
        r1 = 0;
        r2 = 0;
        if get(handle_prec_cont, 'Value')
            for scan = length(data):-1:1
                
                scan_data = data{scan}.prec_scan_data;
                prec = data{scan}.pep_exp_mz; % change this to actual m/z
                scan_data = scan_data(abs(scan_data(:,1) - prec) < cont_window,:);
                
                
                step = 0;
                if isfield(data{scan},'pep_exp_z')
                    step = 1/data{scan}.pep_exp_z;
                end
                
                if step > 0
                    ion_series = prec-5*step:step:prec+5*step;
                    
                    max_int = 0;
                    tol_range = 0.01;
                    for i = 1:length(ion_series)
                        in_range_idx = find(abs(scan_data(:,1) - ion_series(i)) < tol_range);
                        if ~isempty(in_range_idx)
                            max_int = max(max_int,max(scan_data(in_range_idx,2)));
                            scan_data(in_range_idx,2) = 0;
                        end
                    end
                    
                    if (max(scan_data(:,2))/max_int)*100 > cont_thresh
                        if ~isfield(data{scan},'code')
                            data{scan}.code = 'Contaminated Precursor';
                        else
                            data{scan}.code = [data{scan}.code, ' + Contaminated Precursor'];
                        end
                        disp('Contaminated Precursor');
                    end
                else
                    if ~isfield(data{scan},'code')
                        data{scan}.code = 'No Precursor Charge State';
                    else
                        data{scan}.code = [data{scan}.code, ' + No Precursor Charge State'];
                    end
                    disp('No Precursor Charge State');
                end
            end
        end
        disp(['Size of Data: ', num2str(length(data))]);
        
        % Check for Cysteine carbamidomethylation present in MASCOT search
        for i = 1:length(mods)
            if strcmp(mods{i}, 'Carbamidomethyl (C)')
                C_carb = true;
            end
        end
        
        % Check each assignment to each scan
        for i = length(data):-1:1
            disp([num2str(length(data)-i+1), ' of ', num2str(length(data))]);
            print_now(['Validating: ', num2str(length(data)-i+1), ' of ', num2str(length(data))]);
            
            if C_carb && ~isempty(strfind(data{i}.pep_seq,'C'))
                data{i}.pep_seq = regexprep(data{i}.pep_seq,'C', 'c');
            end
            
            % Modify masses of SILAC labeled amino acids for current
            % peptide
            %             global R K k;
            set_R_K(i);
            
            pep_seq = data{i}.pep_seq;
            
            if ~isempty(regexp(pep_seq,'X'))
                if ~isfield(data{i},'code')
                    data{i}.code = 'Unknown Amino Acid';
                else
                    data{i}.code = [data{i}.code, ' + Unknown Amino Acid'];
                end
            end
            if length(pep_seq) > 50
                if ~isfield(data{i},'code')
                    data{i}.code = 'Sequence Too Long';
                else
                    data{i}.code = [data{i}.code, ' + Sequence Too Long'];
                end
            end
            
            % REMOVED QUALIFICATION THAT MASCOT SCORE >= 25!!!
            %             if data{i}.pep_score < 25
            %                 if ~isfield(data{i},'code')
            %                     data{i}.code = 'MASCOT Score < 25';
            %                 else
            %                     data{i}.code = [data{i}.code, ' + MASCOT Score < 25'];
            %                 end
            %             end
            
            if data{i}.num_comb < 11
                poss_seq = gen_possible_seq2_diox(pep_seq, data{i}.pY, data{i}.pSTY, data{i}.oM, data{i}.doM, data{i}.acK);
                
                % Consider all ID's with at least one possible sequence
                if min(size(poss_seq)) > 0 %% && max(size(poss_seq)) < 9
                    
                    % Continue to process all non-excluded IDs
                    if ~isfield(data{i},'code')
                        
                        % Generate fragment masses for all possible sequences
                        % of modifications
                        fragments = fragment_masses2_diox(poss_seq, data{i}.pep_exp_z, 0);
                        
                        % Include all peaks > 1%, only those >10% will be
                        % automatically labeled
                        temp = data{i}.scan_data(:,2)/max(data{i}.scan_data(:,2));
                        temp = find(temp > 0.01);
                        
                        for j = 1:max(size(fragments))
                            if isfield(data{i}, 'scan_type')
                                if strcmp(data{i}.scan_type, 'HCD')
                                    fragments{j}.validated = compare_spectra4(fragments{j}, data{i}.scan_data(temp,:), data{i}.pep_exp_z, data{i}.c13num, HCD_tol);
                                else
                                    fragments{j}.validated = compare_spectra4(fragments{j}, data{i}.scan_data(temp,:), data{i}.pep_exp_z, data{i}.c13num, CID_tol);
                                end
                            else
                                fragments{j}.validated = compare_spectra4(fragments{j}, data{i}.scan_data(temp,:), data{i}.pep_exp_z, data{i}.c13num, CID_tol);
                            end
                            fragments{j}.status = 0;
                        end
                        data{i}.fragments = fragments;
                    end
                else
                    % If no possible sequence of modifications exists, update
                    % ID-specific codes
                    if ~isfield(data{i}, 'code')
                        data{i}.code = 'No Possible Sequence';
                    else
                        data{i}.code = [data{i}.code, ' + No Possible Sequence'];
                    end
                    disp('No Possible Sequence');
                end
            end
        end
    end

    %%% Retrieve Sequences and Assignments for previously excluded ID
    function process_anyway(~, ~)
        print_code_now('Processing...');
        
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue,'\.','split');
        scan = str2num(scan_curr{1});
        
        % Modify masses of SILAC labeled amino acids for current
        % peptide
        set_R_K(scan);
        
        poss_seq = gen_possible_seq2_diox(data{scan}.pep_seq, data{scan}.pY, data{scan}.pSTY, data{scan}.oM, data{scan}.doM, data{scan}.acK);
        
        if min(size(poss_seq)) > 0
            fragments = fragment_masses2_diox(poss_seq, data{scan}.pep_exp_z, 0);
            
            % Include all peaks > 10%
            temp = data{scan}.scan_data(:,2)/max(data{scan}.scan_data(:,2));
            temp = find(temp > 0.01);
            
            for j = 1:max(size(fragments))
                if isfield(data{scan}, 'scan_type')
                    if strcmp(data{scan}.scan_type, 'HCD')
                        fragments{j}.validated = compare_spectra4(fragments{j}, data{scan}.scan_data(temp,:), data{scan}.pep_exp_z, data{scan}.c13num, HCD_tol);
                    else
                        fragments{j}.validated = compare_spectra4(fragments{j}, data{scan}.scan_data(temp,:), data{scan}.pep_exp_z, data{scan}.c13num, CID_tol);
                    end
                else
                    fragments{j}.validated = compare_spectra4(fragments{j}, data{scan}.scan_data(temp,:), data{scan}.pep_exp_z, data{scan}.c13num, CID_tol);
                end
                fragments{j}.status = 0;
            end
            data{scan}.fragments = fragments;
            %
            %             for j = 1:max(size(fragments))
            %                 fragments{j}.validated = compare_spectra(fragments{j}, data{scan}.scan_data(temp,:), CID_tol);
            %                 fragments{j}.status = 0;
            %             end
            %             data{scan}.fragments = fragments;
            data{scan} = rmfield(data{scan},'code');
            
            name = data{scan}.pep_seq;
            [ROW,~] = size(data{scan}.pep_var_mods);
            
            for row = 1:ROW
                if data{scan}.pep_var_mods{row,1} == 1
                    name = [name, ' + ', data{scan}.pep_var_mods{row,2}];
                else
                    name = [name, ' + ', num2str(data{scan}.pep_var_mods{row,1}), ' ', data{scan}.pep_var_mods{row,2}];
                end
            end
            
            node.setName(name);
            set(node,'LeafNode',false);
            mtree.reloadNode(node);
            
            set(handle_process_anyway, ...
                'Visible', 'off', ...
                'Enable', 'off' ...
            );
            print_code_now('');
            
            for j = 1:length(data{scan}.fragments)
                node.add(uitreenode('v0', [num2str(scan),'.',num2str(j)], data{scan}.fragments{j}.seq,  fullfile(images_dir, 'gray.jpg'), true));
            end
        end
    end

    %%% Build uitree in gui
    function [mtree, jtree] = build_tree(filename, data)
        print_now('');
        % Root node
        %         filename = regexprep(filename,'input\','');
        root = uitreenode('v0', 'root', filename, [], false);
        
        prev_prot = '';
        
        num_prot = 1;
        
        prot = uitreenode('v0', 0, 'temp', [], false);
        
        for i = 1:length(data)
            if i == 1
                % First scan
                prot = uitreenode('v0', 'protein', data{i}.protein, fullfile(images_dir, 'white.jpg'), false);
                prev_prot = data{i}.protein;
                num_prot = num_prot + 1;
            elseif ~strcmp(data{i}.protein,prev_prot)
                root.add(prot);
                % First scan of new protein
                prot = uitreenode('v0', 'protein', data{i}.protein, fullfile(images_dir, 'white.jpg'), false);
                prev_prot = data{i}.protein;
                num_prot = num_prot + 1;
            end
            
            name = data{i}.pep_seq;
            
            if isfield(data{i}, 'pep_var_mods')
                [R,~] = size(data{i}.pep_var_mods);
                
                for r = 1:R
                    if data{i}.pep_var_mods{r,1} == 1
                        name = [name, ' + ', data{i}.pep_var_mods{r,2}];
                    else
                        name = [name, ' + ', num2str(data{i}.pep_var_mods{r,1}), ' ', data{i}.pep_var_mods{r,2}];
                    end
                end
            end
            
            
            temp = uitreenode('v0', num2str(i), name, fullfile(images_dir, 'white.jpg'), false);
            temp.UserData = data{i}.scan_number;
            if ~isfield(data{i},'code')
                for j = 1:length(data{i}.fragments)
                    seq = data{i}.fragments{j}.seq;
                    switch data{i}.fragments{j}.status
                        case 0
                            temp.add(uitreenode('v0', [num2str(i),'.',num2str(j)], seq, fullfile(images_dir, 'gray.jpg'), true));
                        case 1
                            temp.add(uitreenode('v0', [num2str(i),'.',num2str(j)], seq, fullfile(images_dir, 'green.jpg'), true));
                            accept_list{end+1}.scan = num2str(i);
                            accept_list{end}.choice = num2str(j);
                        case 2
                            temp.add(uitreenode('v0', [num2str(i),'.',num2str(j)], seq, fullfile(images_dir, 'orange.jpg'), true));
                            maybe_list{end+1}.scan = num2str(i);
                            maybe_list{end}.choice = num2str(j);
                        case 3
                            temp.add(uitreenode('v0', [num2str(i),'.',num2str(j)], seq, fullfile(images_dir, 'red.jpg'), true));
                            reject_list{end+1}.scan = num2str(i);
                            reject_list{end}.choice = num2str(j);
                    end
                end
            else
                set(temp,'LeafNode',true);
                temp.setName(['<html><font color="red">', name,'<html>']);
            end
            
            prot.add(temp);
            
            % Add last protein
            if i == length(data)
                root.add(prot)
            end
        end
        
        %         treeModel = DefaultTreeModel(root);
        %         mtree = uitree('v0'); %, 'Root', root);
        %         mtree.setModel(treeModel);
        %         drawnow;
        mtree = uitree('v0', 'Root', root);
        mtree.setSelectedNode( root );
        mtree.expand( root );
        
        set(mtree, ...
            'Units', 'normalized', ...
            'Position', [0, .1, .17, 0.9] ...
        );
        
        % Use JTree properties from Java
        jtree = handle(mtree.getTree, 'CallbackProperties');
        % MousePressedCallback is not supported by the uitree, but by jtree
        set(jtree, 'MousePressedCallback', @mousePressedCallback);
        set(jtree, 'KeyPressedCallback', @keyPressedCallback);
        
        % Automatically opens javatree to see total progress
        %         node = get(mtree.root,'FirstChild');
        %         while ~isempty(node)
        %             mtree.setSelectedNode(node);
        %             jtree.grabFocus;
        %             tree_row = mtree.Tree.getSelectionRows();
        %             pause(0.1);
        %             mtree.Tree.scrollRowToVisible(tree_row);
        %             mtree.expand(node);
        %             mtree.FigureComponent.getHorizontalScrollBar.setValue(0);
        %             node = get(node,'NextNode');
        %         end
    end

    %%% Displays peptide ladder on gui
    function display_ladder(scan, id)
        % Get the size of the ladder
        [rows, ~] = size(data{scan}.fragments{id}.validated);
        
        seq = data{scan}.fragments{id}.seq;
        
        b_names_keep = {};
        y_names_keep = {};
        
        b_names_keep{length(seq)} = {};
        y_names_keep{length(seq)} = {};
        
        % b_ions = data{scan}.fragments{id}.b_ions;
        % y_ions = data{scan}.fragments{id}.y_ions;
        
        b_used = zeros(length(seq), 1);
        y_used = zeros(length(seq), 1);
        
        for r = 1:rows
            if ~isempty(data{scan}.fragments{id}.validated{r, 2})
                if ~isempty(regexp(data{scan}.fragments{id}.validated{r, 2}, '[a-c]_{', 'once'))
                    matches = regexp(data{scan}.fragments{id}.validated{r, 2}, '[0-9]*', 'match');
                    match_num = str2num(matches{1});
                    
                    b_used(match_num) = 1;
                    b_names_keep{match_num}{end + 1} = data{scan}.fragments{id}.validated{r, 2};
                elseif ~isempty(regexp(data{scan}.fragments{id}.validated{r, 2}, '[x-z]_{', 'once'))
                    matches = regexp(data{scan}.fragments{id}.validated{r, 2}, '[0-9]*', 'match');
                    match_num = str2num(matches{1});
                    
                    y_used(match_num) = 1;
                    y_names_keep{match_num}{end + 1} = data{scan}.fragments{id}.validated{r, 2};
                end
            end
        end
        
        x_start = 0.05;
        y_start = 1.1;
        
        % num_font_size = 5;
        
        % space_x = 20;
        space_x = .015;
        % space_y = 20;
        
        % text(x_start, y_start + space_y, num2str(b_ions(1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
        text( ...
            x_start, y_start, seq(1), ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'Center' ...
        )
        
        prev = x_start;
        
        for i = 2:length(seq)
            % Draw ladders between sequence letters
            if b_used(i-1) == 1 && y_used(end-i+1) == 1
                text( ...
                    prev + space_x, y_start, '\color{red}^{ \rceil}_{ \lfloor}', ...
                    'Units', 'normalized', ...
                    'FontSize', 18, ...
                    'HorizontalAlignment', 'Center', ...
                    'ButtonDownFcn', {@show_used_ions,i-1, length(seq)-i+1} ...
                );
            elseif b_used(i-1) == 1 && y_used(end-i+1) == 0
                text( ...
                    prev + space_x, y_start, '\color{red}^{ \rceil}\color{black}_{ \lfloor}', ...
                    'Units', 'normalized', ...
                    'FontSize', 18, ...
                    'HorizontalAlignment', 'Center',...
                    'ButtonDownFcn', {@show_used_ions, i-1, 0} ...
                );
            elseif b_used(i-1) == 0 && y_used(end-i+1) == 1
                text( ...
                    prev + space_x, y_start, '^{ \rceil}\color{red}_{ \lfloor}', ...
                    'Units', 'normalized', ...
                    'FontSize', 18, ...
                    'HorizontalAlignment', 'Center',...
                    'ButtonDownFcn', {@show_used_ions,0, length(seq)-i+1} ...
                );
            else
                text( ...
                    prev + space_x, y_start, '^{ \rceil}_{ \lfloor}', ...
                    'Units', 'normalized', ...
                    'FontSize', 18, ...
                    'HorizontalAlignment', 'Center' ...
                );
            end
            
            % if i < length(seq)
            %     text(prev + 2*space_x, y_start + space_y, num2str(b_ions(i)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            % end
            text( ...
                prev + 2.25 * space_x, y_start, seq(i), ...
                'Units', 'normalized', ...
                'HorizontalAlignment', 'Center' ...
            );
            % text(prev + 2*space_x, y_start - space_y, num2str(y_ions(end-i+1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            prev = prev + 2 * space_x;
        end
    end

    %%% Plot table of fragments used to confirm sequence positions
    function show_used_ions(~, ~,b_pos, y_pos)
        h2 = figure('pos',[300,300,500,250], 'WindowStyle', 'modal');
        set(gcf,'name','Show Used Fragments','numbertitle','off', 'MenuBar', 'none');
        set(gca,'Position', [0,0,1,1], 'Visible', 'off');
        
        text(.1,.95,'b-ions', 'FontSize', 16);
        if b_pos > 0
            for i = 1:length(b_names_keep{b_pos})
                text(.12, .90 - i*.1, b_names_keep{b_pos}{i});
            end
        end
        
        text(.5,.95,'y-ions', 'FontSize', 16);
        if y_pos > 0
            for i = 1:length(y_names_keep{y_pos})
                text(.52, .90 - i*.1, y_names_keep{y_pos}{i});
            end
        end
    end

    %%% Plot fragment label assignments onto active axes
    function plot_assignment(scan, id, x_start, x_end)
        
        hold on;
        
        % Finds m/z range, sets window +/- 5%
        valid = data{scan}.fragments{id}.validated;
        valid_x = cell2mat(valid(:, 1));
        
        if ~exist('x_start', 'var')
            x_start = 0.95 * valid_x(1);
        end
        if ~exist('x_end', 'var')
            x_end = 1.05 * valid_x(end);
        end
        
        % Only select peaks within our m/z window
        x_range = [x_start, x_end];
        valid = valid(valid_x > x_range(1) & valid_x < x_range(2), :);
        valid_x = cell2mat(valid(:, 1))';
        valid_y = cell2mat(valid(:, 4))';
        
        % Find the maximum intensity
        max_y = max(valid_y);
        
        % Find the number of peaks
        [num_id_peaks_max, ~] = size(valid);
        
        % Make an array of enum elements to assign each scan to a given
        % category
        assignments = zeros(num_id_peaks_max, 1);
        assignments(:) = PeakType.unassigned;
        
        % Process all of the peaks, build a list of misses,
        % below threshold, unknown, isotopes, etc.
        for num_id_peaks = 1:num_id_peaks_max
            % Get m/z of current peak
            x = valid{num_id_peaks, 1};
            
            % Get intensity and name of current peak
            y = valid{num_id_peaks, 4};
            name = valid{num_id_peaks, 2};
            
            % Check for unassigned peaks
            if isempty(name)
                if y / max_y > 0.1
                    assignments(num_id_peaks) = PeakType.missed;
                else
                    assignments(num_id_peaks) = PeakType.below_threshold;
                end
                
                continue
            end
            
            % CHANGED TO ACCOUNT FOR NAMES IN ISOTOPES 10/26/2015
            if strfind(name, 'isotope')
                assignments(num_id_peaks) = PeakType.isotope;
                continue
            end
            
            if strcmp(valid{num_id_peaks, 3}, 'unknown')
                assignments(num_id_peaks) = PeakType.unknown;
            else
                % Check the colision type and the mass accuracy
                if isfield(data{scan}, 'scan_type')
                    if (strcmp(data{scan}.scan_type, 'CID') && valid{num_id_peaks, 5} < CID_tol) || ...
                            (strcmp(data{scan}.scan_type, 'HCD') && valid{num_id_peaks, 5} < HCD_tol)
                        assignments(num_id_peaks) = PeakType.good;
                    else
                        assignments(num_id_peaks) = PeakType.med;
                    end
                else
                    if valid{num_id_peaks, 5} < CID_tol
                        assignments(num_id_peaks) = PeakType.good;
                    else
                        assignments(num_id_peaks) = PeakType.med;
                    end
                end
            end
            text( ...
                x, y, ['  ', name], ...
                'FontSize', 8, ...
                'Rotation', 90, ...
                'ButtonDownFcn', @labelCallback ...
            );
        end
        
        plot_good = [ ...
            valid_x(assignments == PeakType.good); ...
            valid_y(assignments == PeakType.good) ...
        ];
        plot_med = [ ...
            valid_x(assignments == PeakType.med); ...
            valid_y(assignments == PeakType.med) ...
        ];
        plot_isotope = [ ...
            valid_x(assignments == PeakType.isotope); ...
            valid_y(assignments == PeakType.isotope) ...
        ];
        plot_miss = [ ...
            valid_x(assignments == PeakType.missed); ...
            valid_y(assignments == PeakType.missed) ...
        ];
        plot_uk = [ ...
            valid_x(assignments == PeakType.unknown); ...
            valid_y(assignments == PeakType.unknown) ...
        ];
        plot_bt = [ ...
            valid_x(assignments == PeakType.below_threshold); ...
            valid_y(assignments == PeakType.below_threshold) ...
        ];
        
        if ~isempty(plot_good)
            plot(plot_good(1, :), plot_good(2, :), '*g');
        end
        
        if ~isempty(plot_med)
            plot(plot_med(1, :), plot_med(2, :), '*m');
        end
        
        if ~isempty(plot_uk)
            plot(plot_uk(1, :), plot_uk(2, :), '*k');
        end
        
        for i = 1:size(plot_isotope, 2)
            plot( ...
                plot_isotope(1, i), plot_isotope(2, i), '*y', ...
                'ButtonDownFcn', @name_unlabeled ...
            );
        end
        
        for i = 1:size(plot_miss, 2)
            plot( ...
                plot_miss(1, i), plot_miss(2, i), 'or', ...
                'ButtonDownFcn', @name_unlabeled ...
            );
        end
        
        for i = 1:size(plot_bt, 2)
            plot( ...
                plot_bt(1, i), plot_bt(2, i), 'b.', ...
                'ButtonDownFcn', @name_unlabeled ...
            );
        end
        
        ylim([0, 1.25 * max_y]);
        hold off;
    end

    %%% Name a peak
    function name_unlabeled(a,~)
        nodes = mtree.getSelectedNodes;
        node = nodes(1);
        
        scan_curr = regexp(node.getValue,'\.','split');
        scan = str2num(scan_curr{1});
        id = str2num(scan_curr{2});
        
        
        [r,~] = size(data{scan}.fragments{id}.validated);
        mass = get(a,'XData');
        curr_ion = 0;
        for i = 1:r
            if mass == data{scan}.fragments{id}.validated{i,1}
                curr_ion = i;
            end
        end
        
        h2 = figure('pos',[300,300,500,500], 'WindowStyle', 'modal');
        set(gcf,'name','Name Unlabeled Peak','numbertitle','off', 'MenuBar', 'none');
        set(gca,'Position', [0,0,1,1], 'Visible', 'off');
        text(.1,.98,['Observed Mass: ', num2str(data{scan}.fragments{id}.validated{curr_ion,1})]);
        text(.1,.94,'Current Label: None');
        
        %         text(50,400,'New Name:','Units','pixels');
        %         handle_name_unlabeled = uicontrol('Style','edit','Position',[50,400-50,150,20],'Enable','on');
        
        %         uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [25 10 50 20],'Callback', @OKRenameCallback);
        %         uicontrol('Style', 'pushbutton', 'String', 'Cancel','Position', [80 10 50 20],'Callback', @CancelRenameCallback);
        
        rbh = uibuttongroup('Position',[0,0,0.5,0.9],'SelectionChangedFcn', @radioCallback);
        
        [r,~] = size(data{scan}.fragments{id}.validated{curr_ion,6});
        text(280,450,'Mass:','Units','pixels');
        
        if r > 0
            for i = 1:r
                % Show Radio Button with Name
                temp_h = uicontrol('Style','Radio','String', data{scan}.fragments{id}.validated{curr_ion,6}{i,1},'Parent', rbh, 'Position', [20 400 - (i-1)*50 150 20]);
                % Show Mass
                text(280, 410 - (i-1)*50, num2str(data{scan}.fragments{id}.validated{curr_ion,6}{i,3}),'Units','pixels');
            end
            uicontrol('Style','Radio','String', 'Other:','Parent', rbh, 'Position', [20 400 - r*50 200 20]);
            handle_other = uicontrol('Style','edit','Position',[50,400-r*50-20,150,20],'Enable','off');
        else
            uicontrol('Style','Radio','String', 'Other:','Parent', rbh, 'Position', [20 400 - r*50 200 20]);
            handle_other = uicontrol('Style','edit','Position',[50,400-r*50-20,150,20],'Enable','on');
        end
        
        uicontrol('Style', 'pushbutton', 'String', 'OK','Position', [25 10 50 20],'Callback', @OKRenameCallback);
        uicontrol('Style', 'pushbutton', 'String', 'Cancel','Position', [80 10 50 20],'Callback', @CancelRenameCallback);
        
        function radioCallback(a,~)
            if strcmp(get(get(a,'SelectedObject'),'String'),'Other:')
                set(handle_other,'Enable','on');
            else
                set(handle_other,'Enable','off');
            end
        end
        
        function OKRenameCallback(~, ~)
            if strcmp(get(get(rbh,'SelectedObject'),'String'),'Other:')
                if ~isempty(get(handle_other,'String'))
                    data{scan}.fragments{id}.validated{curr_ion,2} = get(handle_other,'String');
                    data{scan}.fragments{id}.validated{curr_ion,3} = 'unknown';
                    data{scan}.fragments{id}.validated{curr_ion,5} = 'unknown';
                else
                    if isempty(data{scan}.fragments{id}.validated{curr_ion,6})
                        data{scan}.fragments{id}.validated{curr_ion,2} = [];
                        data{scan}.fragments{id}.validated{curr_ion,3} = [];
                        data{scan}.fragments{id}.validated{curr_ion,5} = [];
                    end
                end
            else
                name = get(get(rbh,'SelectedObject'),'String');
                data{scan}.fragments{id}.validated{curr_ion,2} = name;
                
                [r,~] = size(data{scan}.fragments{id}.validated{curr_ion,6});
                chosen_id = 0;
                for i = 1:r
                    if strcmp(data{scan}.fragments{id}.validated{curr_ion,6}{i,1},name)
                        chosen_id = i;
                    end
                end
                data{scan}.fragments{id}.validated{curr_ion,3} = data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3};
                data{scan}.fragments{id}.validated{curr_ion,5} = abs(data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3}-data{scan}.fragments{id}.validated{curr_ion,1})/data{scan}.fragments{id}.validated{curr_ion,6}{chosen_id,3};
            end
            cla(ax1_assign);
            axes(ax1_assign);
            display_ladder(scan,id);
            plot_assignment(scan,id);
            close(h2);
        end
        
        function CancelRenameCallback(~, ~)
            close(h2);
        end
    end

    %%% Plot iTRAQ region data onto active axes
    function plot_iTRAQ(scan)
        %         axes(ax3);
        title('iTRAQ/TMT');
        hold on;
        if ~isempty(data{scan}.iTRAQ_scan_data)
            mz = data{scan}.iTRAQ_scan_data(:,1);
            int = data{scan}.iTRAQ_scan_data(:,2);
            ylim([0,max(1,1.1*max(int))]);
        else
            mz = [];
            int = [];
        end
        stem(mz,int, 'Marker', 'none');
        
        if iTRAQType{2} == 8
            xlim([112,122]);
        elseif iTRAQType{2} == 4
            xlim([113,118]);
        elseif (iTRAQType{2} == 6 || iTRAQType{2} == 10) %***
            xlim([125 132])
        end
        
        for i = 1:length(iTRAQ_masses)
            idx2 = [];
            val_int = [];
            idx = find(abs(mz-iTRAQ_masses(i)) < 0.005); %*** Changed for doublets
            [val_int,idx2] = max(int(idx));
            
            if ~isempty(idx2)
                if iTRAQType{2} == 10
                    if i == 1
                        plot(iTRAQ_masses(i), val_int, '*g');
                    elseif any(i == [2,4,6,8]) % Colors N channels red
                        % plot(iTRAQ_masses(i), val_int, '>r');
                        text(iTRAQ_masses(i)-0.25, val_int, 'N', 'color', 'r')
                    elseif any(i == [3,5,7,9]) % Colors C channels cyan
                        % plot(iTRAQ_masses(i), val_int, '<c');
                        text(iTRAQ_masses(i)-0.25, val_int, 'C', 'color', 'b')
                    elseif i == 10
                        plot(iTRAQ_masses(i), val_int, '*g');
                    end
                else
                    plot(iTRAQ_masses(i), val_int, '*g');
                end
            end
        end
        hold off;
    end

    %%% Plot precursor region data onto active axes
    function plot_prec(scan)
        
        title('Precursor');
        hold on;
        
        prec = data{scan}.pep_exp_mz;
        
        if isfield(data{scan}, 'prec_scan_data')
            mz = data{scan}.prec_scan_data(:,1);
            int = data{scan}.prec_scan_data(:,2);
            
            scale = 1.1 * max(int);
        else
            mz = [];
            int = [];
            
            scale = 1;
        end
        ylim([0,scale]);
        
        if ~SILAC
            xlim([prec-2,prec+2]);
        else
            xlim([data{scan}.SILAC_prec(1) - 2,data{scan}.SILAC_prec(3) + 2]);
        end
        
        % Lightly highlight all SILAC precursor peaks
        if SILAC
            for i = 1:length(data{scan}.SILAC_prec)
                area([data{scan}.SILAC_prec(i)-cont_window,data{scan}.SILAC_prec(i)+cont_window],[scale,scale],'FaceColor', [.95,.95,.95],'LineStyle','none');
            end
        end
        % Darkly highlight fragmented SILAC precursor peak
        area([prec-cont_window,prec+cont_window],[scale,scale],'FaceColor', [.75,.75,.75],'LineStyle','none');
        
        step = 1/data{scan}.pep_exp_z;
        
        ion_series = [];
        if ~SILAC
            ion_series = prec-5*step:step:prec+5*step;
        else
            for i = 1:length(data{scan}.SILAC_prec)
                ion_series = [ion_series, data{scan}.SILAC_prec(i)-5*step:step:data{scan}.SILAC_prec(i)+5*step];
            end
        end
        
        if ~isempty(mz)
            stem(mz,int, 'Marker', 'none');
            for i = 1:length(ion_series)
                [diff,idx] = min(abs(ion_series(i)-mz));
                if (diff/ion_series(i) < HCD_tol) && (int(idx)/max(int) > 0.1) % Decreased Tolerance from 0.05 to HCD_tol
                    plot(mz(idx), int(idx), '*g');
                end
            end
        end
        
        
        
        hold off;
    end

    %%% Print PDF containing MS2 with assignment, peptide ladder, iTRAQ,
    %   precursor, and run information
    function print_pdf(scan, id, fig_path)
        seq = data{scan}.fragments{id}.seq;
        protein = data{scan}.protein;
        charge_state = data{scan}.pep_exp_z;
        scan_number = data{scan}.scan_number;
        
        %         b_ions = data{scan}.fragments{id}.b_ions;
        %         y_ions = data{scan}.fragments{id}.y_ions;
        
        b_used = zeros(length(seq),1);
        y_used = zeros(length(seq),1);
        
        [R,~] = size(data{scan}.fragments{id}.validated);
        for r = 1:R
            if ~isempty(data{scan}.fragments{id}.validated{r,2})
                if ~isempty(regexp(data{scan}.fragments{id}.validated{r,2},'a_{')) || ~isempty(regexp(data{scan}.fragments{id}.validated{r,2},'b_{'))
                    [~,~,~,d] = regexp(data{scan}.fragments{id}.validated{r,2},'[0-9]*');
                    b_used(str2num(d{1})) = 1;
                elseif ~isempty(regexp(data{scan}.fragments{id}.validated{r,2},'y_{'))
                    [~,~,~,d] = regexp(data{scan}.fragments{id}.validated{r,2},'[0-9]*');
                    y_used(str2num(d{1})) = 1;
                end
            end
        end
        
        fig = figure('pos', [150, 100, 1200, 600]);
        set(gca,'Visible','off');
        % Print PDF friendly scan information and ladder
        
        ytext = 500;
        xtext = 0;
        delta = 10;
        
        text(xtext, ytext, protein, 'Units', 'pixels', 'FontSize', 10);
        text(xtext, ytext-delta, ['Charge State: +', num2str(charge_state)], 'Units', 'pixels', 'FontSize', 10);
        text(xtext, ytext-2*delta, ['Scan Number: ', num2str(scan_number)], 'Units', 'pixels', 'FontSize', 10);
        
        if isempty(RAW_filename)
            text(xtext, ytext-3*delta, ['File Name: ', filename, '.RAW'], 'Units', 'pixels', 'FontSize', 10, 'Interpreter', 'none');
        else
            text(xtext, ytext-3*delta, ['File Name: ', RAW_filename], 'Units', 'pixels', 'FontSize', 10, 'Interpreter', 'none');
        end
        %         text(-40, 620, ['File Name: ', filename, '.raw'], 'Units', 'pixels', 'FontSize', 10, 'Interpreter', 'none');
        
        x_start = xtext;
        y_start = ytext-5*delta;
        
        num_font_size = 5;
        
        %         space_x = 20;
        space_x = 10;
        %         space_y = 20;
        
        %         text(x_start, y_start + space_y, num2str(b_ions(1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
        text(x_start, y_start, seq(1), 'Units', 'pixels', 'HorizontalAlignment', 'Center')
        
        prev = x_start;
        
        for i = 2:length(seq)
            if b_used(i-1) == 1 && y_used(end-i+1) == 1
                text(prev + space_x, y_start, '\color{red}^{ \rceil}_{ \lfloor}','Units','pixels','FontSize', 18,'HorizontalAlignment', 'Center');
            elseif b_used(i-1) == 1 && y_used(end-i+1) == 0
                text(prev + space_x, y_start, '\color{red}^{ \rceil}\color{black}_{ \lfloor}','Units','pixels','FontSize', 18,'HorizontalAlignment', 'Center');
            elseif b_used(i-1) == 0 && y_used(end-i+1) == 1
                text(prev + space_x, y_start, '^{ \rceil}\color{red}_{ \lfloor}','Units','pixels','FontSize', 18,'HorizontalAlignment', 'Center');
            else
                text(prev + space_x, y_start, '^{ \rceil}_{ \lfloor}','Units','pixels','FontSize', 18,'HorizontalAlignment', 'Center');
            end
            
            %             if i < length(seq)
            %                 text(prev + 2*space_x, y_start + space_y, num2str(b_ions(i)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            %             end
            text(prev + 2.25*space_x, y_start, seq(i), 'Units', 'pixels', 'HorizontalAlignment', 'Center');
            %             text(prev + 2*space_x, y_start - space_y, num2str(y_ions(end-i+1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            prev = prev + 2*space_x;
            
            %             if b_used(i-1) == 1 && y_used(end-i+1) == 1
            %                 text(prev + space_x, y_start, '\color{red}^{ \rceil}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            %             elseif b_used(i-1) == 1 && y_used(end-i+1) == 0
            %                 text(prev + space_x, y_start, '\color{red}^{ \rceil}\color{black}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            %             elseif b_used(i-1) == 0 && y_used(end-i+1) == 1
            %                 text(prev + space_x, y_start, '^{ \rceil}\color{red}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            %             else
            %                 text(prev + space_x, y_start, '^{ \rceil}_{ \lfloor}', 'Units', 'pixels', 'FontSize', 18, 'HorizontalAlignment', 'Center');
            %            end
            
            %             if i < length(seq)
            %                 text(prev + 2*space_x, y_start + space_y, num2str(b_ions(i)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            %             end
            %            text(prev + 2*space_x, y_start, seq(i), 'Units', 'pixels', 'HorizontalAlignment', 'Center');
            %             text(prev + 2*space_x, y_start - space_y, num2str(y_ions(end-i+1)), 'Units', 'pixels', 'HorizontalAlignment', 'Center', 'FontSize', num_font_size);
            %            prev = prev + 2*space_x;
        end
        
        
        ax1_pdf = axes('Position', [.12,.125,.6,.65], 'TickDir', 'out', 'box', 'off');
        ax2_pdf = axes('Position', [.75,.5,.14,.25], 'TickDir', 'out', 'box', 'off');
        title('Precursor');
        
        
        axes(ax1_pdf);
        ylim([0,1.25*max(data{scan}.scan_data(:,2))]);
        
        x_start = 0.95 * data{scan}.fragments{id}.validated{1,1};
        x_end = 1.05 * data{scan}.fragments{id}.validated{end,1};
        xlim([x_start,x_end]);
        
        stem(data{scan}.scan_data(:,1),data{scan}.scan_data(:,2),'Marker', 'none');
        plot_assignment(scan,id);
        set(gca, 'TickDir', 'out', 'box', 'off');
        
        
        axes(ax2_pdf);
        plot_prec(scan);
        set(gca, 'TickDir', 'out', 'box', 'off');
        %         text(.5,1.1,'Precursor', 'HorizontalAlignment', 'center');
        if ~strcmp(iTRAQType{1},'None')
            ax3_pdf = axes('Position', [.75,.125,.14,.25], 'TickDir', 'out', 'box', 'off');
            title('iTRAQ/TMT');
            
            axes(ax3_pdf);
            plot_iTRAQ(scan);
            set(gca, 'TickDir', 'out', 'box', 'off');
            %         text(.5,1.1,'iTRAQ', 'HorizontalAlignment', 'center');
        end
        
        orient landscape;
        paperUnits = get(fig, 'PaperUnits');
        set(fig, 'PaperUnits','inches');
        paperSize = get(fig,'PaperSize');
        paperPosition = [-1 -.5 paperSize + [2 .5]];
        set(fig, 'PaperPosition', paperPosition);
        set(fig, 'PaperUnits',paperUnits);
        
        [dir_temp, filename_temp, ext_temp] = fileparts(fig_path);
        filename_temp = regexprep(filename_temp,'<','');
        filename_temp = regexprep(filename_temp,'>','');
        filename_temp = regexprep(filename_temp,':','');
        filename_temp = regexprep(filename_temp,'"','');
        filename_temp = regexprep(filename_temp,'/','');
        % filename_temp = regexprep(filename_temp,'\','');
        filename_temp = regexprep(filename_temp,'\|','');
        filename_temp = regexprep(filename_temp,'?','');
        filename_temp = regexprep(filename_temp,'*','');
        
        print(fig, '-dpdf', '-r900', fullfile(dir_temp, [filename_temp, ext_temp]));
        
        close(fig);
    end
    
    %%% Write XLS file with iTRAQ data for scans in list
    function iTRAQ_to_Excel(excel_list, out_path)
        XLS_out = fopen(out_path, 'w');
        
        title_line = [ ...
            'Scan\t', ...
            'Protein\t', ...
            'Accession\t', ...
            'Sequence\t', ...
            'Score'...
        ];
        for i = 1:length(iTRAQ_labels)
            title_line = [title_line, '\t', iTRAQ_labels{i}];
        end
        title_line = [title_line, '\n'];
        fprintf(XLS_out, title_line);
        
        for i = 1:length(excel_list)
            scan = str2num(excel_list{i}.scan);
            id = str2num(excel_list{i}.choice);
            
            line = [ ...
                num2str(data{scan}.scan_number), '\t', ...
                data{scan}.protein, '\t', ...
                data{scan}.gi, '\t', ...
                data{scan}.fragments{id}.seq, '\t', ...
                num2str(round(data{scan}.pep_score)) ...
            ];
            
            %%%
            if ~isempty(data{scan}.iTRAQ_scan_data)
                mz = data{scan}.iTRAQ_scan_data(:,1);
                int = data{scan}.iTRAQ_scan_data(:,2);
            else
                mz = [];
                int = [];
            end
            
            for j = 1:length(iTRAQ_masses)
                idx2 = [];
                val_int = [];
                idx = find(abs(mz-iTRAQ_masses(j)) < 0.005); %*** Changed to account for doublets
                [val_int,idx2] = max(int(idx));
                
                if ~isempty(idx2)
                    line = [line, '\t', num2str(val_int)];
                else
                    line = [line, '\t', num2str(0)];
                end
            end
            line = [line, '\n'];
            fprintf(XLS_out, line);
        end
        fclose(XLS_out);
    end

    %%% Write XLS file with just the peptides and modifications in list
    function unlabelled_to_Excel(excel_list, out_path)
        XLS_out = fopen(out_path, 'w');
        title_line = ['Scan\t', 'Protein\t', 'Accession\t', 'Sequence\n'];
        fprintf(XLS_out, title_line);
        
        for i = 1:length(excel_list)
            scan = str2num(excel_list{i}.scan);
            id = str2num(excel_list{i}.choice);
            
            line = [num2str(data{scan}.scan_number), '\t', data{scan}.protein, '\t', data{scan}.gi, '\t', data{scan}.fragments{id}.seq, '\n'];
            fprintf(XLS_out, line);
        end
        fclose(XLS_out);
    end

    %%% Write XLS file with SILAC data for scans in list
    function SILAC_to_Excel(excel_list, out_path)
        XLS_out = fopen(out_path, 'w');
        
        title_line = ['Scan\t', 'Protein\t', 'Accession\t', 'Sequence\t', 'SILAC Centroided\n'];
        fprintf(XLS_out, title_line);
        
        for i = 1:length(excel_list)
            scan = str2num(excel_list{i}.scan);
            id = str2num(excel_list{i}.choice);
            
            line = [num2str(data{scan}.scan_number), '\t', data{scan}.protein, '\t', data{scan}.gi, '\t', data{scan}.fragments{id}.seq];
            
            %%%
            mz = data{scan}.prec_scan_data(:,1);
            int = data{scan}.prec_scan_data(:,2);
            prec = data{scan}.SILAC_prec;
            
            for j = 1:length(prec)
                idx2 = [];
                val_int = [];
                idx = find(abs(mz-prec(j)) < 0.25);
                [val_int,idx2] = max(int(idx));
                
                if ~isempty(idx2)
                    line = [line, '\t', num2str(val_int)];
                else
                    line = [line, '\t', num2str(0)];
                end
            end
            line = [line, '\n'];
            fprintf(XLS_out, line);
        end
        fclose(XLS_out);
    end

    %%% Set masses of Arginine and Lysine based on SILAC and iTRAQ
    function set_R_K(scan)
        global R K k;
        
        % Set mass of Arginine (R)
        if data{scan}.r6 > 0
            R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0);
        elseif data{scan}.r10 > 0
            R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass2([0 0],[-6 6],[-4 4],[0 0 0],[0 0 0 0],0);
        else
            R = exact_mass(14,6,4,2,0,0) - exact_mass(2,0,0,1,0,0);
        end
        
        % Set mass of Lysine (K)
        if data{scan}.k6 > 0
            K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0);
            % Acetyl Lysine
            k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0) + exact_mass2([0 0],[-6 6],[0 0],[0 0 0],[0 0 0 0],0);
        elseif data{scan}.k8 > 0
            K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + exact_mass2([0 0],[-6 6],[-2 2],[0 0 0],[0 0 0 0],0);
            % Acetyl Lysine
            k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0) + exact_mass2([0 0],[-6 6],[-2 2],[0 0 0],[0 0 0 0],0);
        else
            %-----------------------------%
            var_8plex = 0;
            var_4plex = 0;
            var_6plex = 0;
            var_10plex = 0;
            
            if isfield(data{scan}, 'pep_var_mods')
                curr_var_mods = data{scan}.pep_var_mods;
                [row, col] = size(curr_var_mods);
                for idx = 1:row
                    if ~isempty(regexp(curr_var_mods{idx,2},'iTRAQ4plex (K)'))
                        var_4plex = 1;
                    elseif ~isempty(regexp(curr_var_mods{idx,2},'iTRAQ8plex (K)'))
                        var_8plex = 1;
                    elseif ~isempty(regexp(curr_var_mods{idx,2},'TMT10plex (K)')) %***
                        var_10plex = 1;
                    elseif ~isempty(regexp(curr_var_mods{idx,2},'TMT6plex (K)'))  %***
                        var_6plex = 1;
                    end
                end
            end
            %-----------------------------%
            % Lysine iTRAQ labeled
            if iTRAQType{2} == 4 || var_4plex
                iTRAQ = 144.1021 + exact_mass(1,0,0,0,0,0);
                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
            elseif iTRAQType{2} == 8 || var_8plex
                iTRAQ = 304.2054 + exact_mass(1,0,0,0,0,0);
                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
            elseif ((iTRAQType{2} == 10 || var_10plex) || (iTRAQType{2} == 6 || var_6plex))  %***
                iTRAQ = 229.1629 + exact_mass(1,0,0,0,0,0);
                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) + iTRAQ - exact_mass(1,0,0,0,0,0);
            else
                K = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0);
            end
            % Acetyl Lysine, not iTRAQ labeled
            k = exact_mass(14,6,2,2,0,0) - exact_mass(2,0,0,1,0,0) - exact_mass(1,0,0,0,0,0) + exact_mass(3,2,0,1,0,0);
        end
    end

% Extracts isolation m/z's for each scan from msconverts


end
