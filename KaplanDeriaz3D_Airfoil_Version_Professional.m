% KaplanDeriaz3D - Hydro Turbine Blade Designer with CAD/Excel Export
% Copyright (C) 2026 Juan Fernandez Lozano
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>

classdef KaplanDeriaz3D_Airfoil_Version_Professional < handle
    % KaplanDeriaz3D_Airfoil_Version: Hydro Turbine Blade Designer with CAD/Excel Export
    
    properties
        UIFigure
        MainGrid
        LeftScrollPanel
        LeftGrid
        RightMainGrid
        RendersGrid   
        Axes3D_Mid    
        Axes3D_Solid  
        ColorbarMid
        ColorbarSolid

        % Header / Menu / Status Bar (Professional Edition additions)
        HeaderPanel
        StatusBarPanel
        StatusLabel
        LastComputedLabel
        MenuFile
        MenuView
        MenuHelp
        
        % Common Controls
        TurbineTypeDropDown
        RPMEdit
        RotationDropDown
        Q0Edit
        HnEdit
        gEdit
        EtaHEdit
        EtaVEdit
        EtaOEdit
        SigmaEdit
        InterpDropDown
        
        % Airfoil Design Controls
        AirfoilPanel
        NACADropDown      
        ThicknessEdit
        
        % Kaplan Controls
        KaplanPanel
        RCuboEdit
        RPuntaEdit
        LzEdit
        
        % Deriaz Controls
        DeriazPanel
        ReIntEdit
        ReExtEdit
        Gamma1Edit
        Gamma2Edit
        
        % Advanced Options
        AdvPanel
        NRadiosEdit
        NCuerdaEdit
        
        % Export Panel Controls
        ExportPanel
        ExportTypeDropDown
        ExportFormatDropDown
        ExportCADBtn
        ExportExcelBtn
        
        % Buttons and State
        ComputeBtn
        ResultsTable   
        
        % Blade Geometry Data
        X_mid, Y_mid, Z_mid
        X_sol_ext, Y_sol_ext, Z_sol_ext 
        X_sol_int, Y_sol_int, Z_sol_int 
        RC_grid 
        
        % Closed Cap Data
        CapsX, CapsY, CapsZ, CapsC
        
        % Hydro-Calculated Data for Excel
        RadiusVec
        Beta1_deg
        Beta2_deg
        
        IsComputed = false
        Z_optimo_current

        % --- AÑADE ESTAS LÍNEAS PARA LAS PESTAÑAS ---
    TabGroup        
    TabGeneral      
    TabHydro        
    HydroGrid       
    HydroControlPanel 
    HydroPlotPanel  
    AxesHydro       
    HydroScrollPanel
    ComputeBtn2
    HubToTipRatioEdit
    % Controles para el perfil Customized
    MHubEdit
    PHubEdit
    MTipEdit
    PTipEdit
    CustomPanel
    end
    
    methods
        function app = KaplanDeriaz3D_Airfoil_Version_Professional()
            % Check component environment
            if ~exist('uifigure', 'file')
                error('MATLAB App Designer UI components are required. Please run this script in MATLAB R2019b or newer (uiprogressdlg and uimenu-on-uifigure are used by this Professional Edition).');
            end
            app.createUI();
            app.onTurbineTypeChange();
            app.validateGeometryFields();
        end
        
        function createUI(app)
    %% 1. MAIN WINDOW
    screenSize = get(0, 'ScreenSize');
    figWidth  = min(1600, screenSize(3) * 0.85);
    figHeight = min(920,  screenSize(4) * 0.85);
    posX = max(10, (screenSize(3) - figWidth) / 2);
    posY = max(30, (screenSize(4) - figHeight) / 2);
    
    app.UIFigure = uifigure('Name', 'KaplanDeriaz3D Airfoil Version - Professional Edition', ...
        'Position', [posX, posY, figWidth, figHeight], 'Color', [0.94 0.95 0.97]);

    %% 1b. MENU BAR (File / View / Help)
    % Nota: uimenu sobre uifigure requiere MATLAB R2018a o superior (igual que
    % uiprogressdlg, usado mas abajo, requiere R2019b+).
    app.MenuFile = uimenu(app.UIFigure, 'Text', '&File');
    uimenu(app.MenuFile, 'Text', 'Save Configuration...', 'MenuSelectedFcn', @(~,~) app.saveConfiguration());
    uimenu(app.MenuFile, 'Text', 'Load Configuration...', 'MenuSelectedFcn', @(~,~) app.loadConfiguration());
    uimenu(app.MenuFile, 'Text', 'Reset to Defaults', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) app.resetToDefaults());
    uimenu(app.MenuFile, 'Text', 'Export CAD Geometry...', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) app.exportCAD());
    uimenu(app.MenuFile, 'Text', 'Export Blade Angles (Excel)...', 'MenuSelectedFcn', @(~,~) app.exportExcel());
    uimenu(app.MenuFile, 'Text', 'Close', 'Separator', 'on', 'MenuSelectedFcn', @(~,~) close(app.UIFigure));

    app.MenuView = uimenu(app.UIFigure, 'Text', '&View');
    uimenu(app.MenuView, 'Text', 'Reset 3D View', 'MenuSelectedFcn', @(~,~) app.resetView());
    uimenu(app.MenuView, 'Text', 'Copy Results Table', 'MenuSelectedFcn', @(~,~) app.copyResultsToClipboard());

    app.MenuHelp = uimenu(app.UIFigure, 'Text', '&Help');
    uimenu(app.MenuHelp, 'Text', 'About KaplanDeriaz3D...', 'MenuSelectedFcn', @(~,~) app.showAbout());

    % MainGrid: fila de cabecera + fila de contenido (2 columnas) + barra de estado
    app.MainGrid = uigridlayout(app.UIFigure, [3, 2]);
    app.MainGrid.RowHeight = {54, '1x', 26};
    app.MainGrid.ColumnWidth = {440, '1x'};
    app.MainGrid.RowSpacing = 6;
    app.MainGrid.Padding = [8 8 8 6];

    %% 1c. HEADER BANNER
    app.HeaderPanel = uipanel(app.MainGrid, 'BorderType', 'none', 'BackgroundColor', [0.10 0.22 0.38]);
    app.HeaderPanel.Layout.Row = 1; app.HeaderPanel.Layout.Column = [1 2];
    headerGrid = uigridlayout(app.HeaderPanel, [2, 1]);
    headerGrid.RowHeight = {22, 18}; headerGrid.Padding = [14 4 14 4]; headerGrid.RowSpacing = 0;
    titleLbl = uilabel(headerGrid, 'Text', 'KaplanDeriaz3D — Hydraulic Turbine Blade Designer', ...
        'FontSize', 15, 'FontWeight', 'bold', 'FontColor', [0 0 0]);
    titleLbl.Layout.Row = 1;
    subtitleLbl = uilabel(headerGrid, 'Text', 'Solid Turbine Designer with CAD / Excel Export — Kaplan (Axial) & Deriaz (Diagonal) Runners', ...
        'FontSize', 10, 'FontColor', [0.25 0.25 0.75]);
    subtitleLbl.Layout.Row = 2;

    %% 2. LEFT TAB GROUP (Ubicado en la columna 1, fila de contenido)
    app.TabGroup = uitabgroup(app.MainGrid);
    app.TabGroup.Layout.Row = 2; 
    app.TabGroup.Layout.Column = 1;
    
    app.TabGeneral = uitab(app.TabGroup, 'Title', ' General ');
    app.TabHydro   = uitab(app.TabGroup, 'Title', ' Hydrofoil & mesh ');
    
    %% ====================================================================
    %% PESTAÑA 1: PARÁMETROS GENERALES
    %% ====================================================================
    gridTab1 = uigridlayout(app.TabGeneral, [1, 1]); gridTab1.Padding = [0 0 0 0];
    
    app.LeftScrollPanel = uipanel(gridTab1, 'Title', ' Design Parameters ', ...
        'FontWeight', 'bold', 'FontSize', 11, 'Scrollable', 'on');
    
    container1 = uipanel(app.LeftScrollPanel, 'BorderType', 'none');
    container1.Position = [0 0 238 625]; 
    
    % Layout para Pestaña 1 (14 filas)
    app.LeftGrid = uigridlayout(container1, [14, 2]);
    app.LeftGrid.RowSpacing = 3; app.LeftGrid.Padding = [8 6 10 4];
    app.LeftGrid.RowHeight = {22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 'fit', 38, 'fit'};
    app.LeftGrid.ColumnWidth = {170, '1x'};
    
    % --- Inputs Pestaña 1 ---
    r = 1;
            lbl = uilabel(app.LeftGrid, 'Text', 'Turbine Type:', 'FontWeight', 'bold');
            lbl.Tooltip = sprintf([ ...
                'Hydraulic Turbine Type:\n' ...
                '• Kaplan (Axial): Purely axial flow. Optimal for low heads (Hn < 40m) and large flow rates.\n' ...
                '• Deriaz (Diagonal): Diagonal/mixed flow. Ideal for medium heads (40m < Hn < 200m) and reversible pumped storage.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            
            app.TurbineTypeDropDown = uidropdown(app.LeftGrid, 'Items', {'Kaplan (Axial)', 'Deriaz (Diagonal)'}, 'ValueChangedFcn', @(~,~) app.onTurbineTypeChange());
            app.TurbineTypeDropDown.Layout.Row = r; app.TurbineTypeDropDown.Layout.Column = 2;
            
            r = 2; lbl = uilabel(app.LeftGrid, 'Text', 'Rotational Speed (RPM):'); 
            lbl.Tooltip = sprintf([ ...
                'Runner Rotational Speed (N in RPM):\n' ...
                '• Sets the angular speed of the shaft (\x03C9 = 2\x03C0N/60).\n' ...
                '• Directly impacts the inlet and outlet velocity triangles by altering the peripheral speed (u = \x03C9·r).\n' ...
                '• Must synchronize with the grid frequency according to the generator pole pairs.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.RPMEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 450); app.RPMEdit.Layout.Row = r; app.RPMEdit.Layout.Column = 2;
            
            r = 3; lbl = uilabel(app.LeftGrid, 'Text', 'Rotation Direction:'); 
            lbl.Tooltip = sprintf([ ...
                'Runner Direction of Rotation:\n' ...
                '• Counter-Clockwise (Standard): Standard for most turbines when viewed from downstream.\n' ...
                '• Clockwise: Inverts blade kinematic orientation and tangential flow components.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.RotationDropDown = uidropdown(app.LeftGrid, 'Items', {'Counter-Clockwise (Standard)', 'Clockwise'}); app.RotationDropDown.Layout.Row = r; app.RotationDropDown.Layout.Column = 2;
            
            r = 4; lbl = uilabel(app.LeftGrid, 'Text', 'Flow Rate Q0 (m³/s):'); 
            lbl.Tooltip = sprintf([ ...
                'Nominal Volumetric Flow Rate (Q0):\n' ...
                '• Total volume of water passing through the runner per second.\n' ...
                '• Along with the flow area, it determines the meridian flow velocity (Vm = Q_effective / A_flow), fixing the streamline slopes.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.Q0Edit = uieditfield(app.LeftGrid, 'numeric', 'Value', 12); app.Q0Edit.Layout.Row = r; app.Q0Edit.Layout.Column = 2;
            
            r = 5; lbl = uilabel(app.LeftGrid, 'Text', 'Net Head Hn (m):'); 
            lbl.Tooltip = sprintf([ ...
                'Net Head / Effective Head (Hn):\n' ...
                '• Specific energy available per unit weight of fluid between turbine inlet and outlet.\n' ...
                '• Governs total hydraulic power available (Ph = \x03C1·g·Q0·Hn) and the tangential velocity Vtheta for all streamlines']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.HnEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 15); app.HnEdit.Layout.Row = r; app.HnEdit.Layout.Column = 2;
            
            r = 6; lbl = uilabel(app.LeftGrid, 'Text', 'Gravity g (m/s²):'); 
            lbl.Tooltip = sprintf('Local gravitational acceleration (typically 9.81 m/s²).');
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.gEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 9.81); app.gEdit.Layout.Row = r; app.gEdit.Layout.Column = 2;
            
            r = 7; lbl = uilabel(app.LeftGrid, 'Text', 'Hydraulic Eff. (eta_h):'); 
            lbl.Tooltip = sprintf([ ...
                'Hydraulic Efficiency (\x03B7_h):\n' ...
                '• Evaluates head losses due to friction, boundary layer separation, and inlet shock.\n' ...
                '• Modifies effective Eulerian head transferred to the shaft: H_euler = Hn · \x03B7_h.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.EtaHEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 0.90, 'Limits', [0.1 1]); app.EtaHEdit.Layout.Row = r; app.EtaHEdit.Layout.Column = 2;
            
            r = 8; lbl = uilabel(app.LeftGrid, 'Text', 'Volumetric Eff. (eta_v):'); 
            lbl.Tooltip = sprintf([ ...
                'Volumetric Efficiency (\x03B7_v):\n' ...
                '• Quantifies leakage losses through peripheral tip/hub clearances.\n' ...
                '• Effective flow rate performing useful work: Q_effective = Q0 · \x03B7_v.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.EtaVEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 0.96, 'Limits', [0.1 1]); app.EtaVEdit.Layout.Row = r; app.EtaVEdit.Layout.Column = 2;
            
            r = 9; lbl = uilabel(app.LeftGrid, 'Text', 'Mechanical Eff. (eta_m):'); 
            lbl.Tooltip = sprintf([ ...
                'Mechanical Efficiency (\x03B7_m):\n' ...
                '• Accounts for mechanical friction losses in bearings, seals, and shaft components.\n' ...
                '• Total Turbine Efficiency: \x03B7_total = \x03B7_h · \x03B7_v · \x03B7_m.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.EtaOEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 0.98, 'Limits', [0.1 1]); app.EtaOEdit.Layout.Row = r; app.EtaOEdit.Layout.Column = 2;
            
            r = 10; lbl = uilabel(app.LeftGrid, 'Text', 'Solidity (sigma):'); 
            lbl.Tooltip = sprintf([ ...
                'Runner Solidity (\x03C3 = Lc / t):\n' ...
                '• Ratio between mean blade chord (Lc) and tangential pitch (t = 2\x03C0r / Z).\n' ...
                '• DIRECT BLADE IMPACT: Higher solidity (\x03C3) requires more blades (Z) or longer chords to distribute hydrodynamic loading.\n' ...
                '• High values (\x03C3 > 1.3) mitigate cavitation risk but increase viscous friction losses.']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.SigmaEdit = uieditfield(app.LeftGrid, 'numeric', 'Value', 1.25, 'Limits', [0.5 3]); app.SigmaEdit.Layout.Row = r; app.SigmaEdit.Layout.Column = 2;
            
           r = 11; lbl = uilabel(app.LeftGrid, 'Text', 'Interpolation Scheme:'); 
            lbl.Tooltip = sprintf([ ...
                'Beta Angle Distribution Law (Pressure distribution along chord):\n' ...
                '• Cubic (Standard): Smooth distribution. Peak hydrodynamic pressure located around 30-40%% of chord length.\n' ...
                '• Linear (Uniform): Constant angle gradient. Pressure is distributed uniformly along the profile.\n' ...
                '• Cosine (Smooth): Ultra-smooth transition near leading/trailing edges. Minimizes localized cavitation spikes.\n' ...
                '• Inlet Loaded: Steeper deflection at the entry. MAXIMUM PRESSURE ZONE AT LEADING EDGE (ideal for clean, shock-free flow entry).\n' ...
                '• Outlet Loaded: Steeper curvature towards the exit. MAXIMUM PRESSURE ZONE AT TRAILING EDGE (maximizes energy transfer before discharge).']);
            lbl.Layout.Row = r; lbl.Layout.Column = 1;
            app.InterpDropDown = uidropdown(app.LeftGrid, 'Items', {'Cubic (Standard)', 'Linear (Uniform)', 'Cosine (Smooth)', 'Inlet Loaded (Attack)', 'Outlet Loaded (Discharge)'}); 
            app.InterpDropDown.Layout.Row = r; app.InterpDropDown.Layout.Column = 2;

            
            %% Geometry Sub-Panels (Row 12)
            r = 12;
            app.KaplanPanel = uipanel(app.LeftGrid, 'Title', 'Kaplan Geometry', 'FontWeight', 'bold');
            app.KaplanPanel.Layout.Row = r; app.KaplanPanel.Layout.Column = [1 2];
            kg = uigridlayout(app.KaplanPanel, [3, 2]); kg.RowSpacing = 4; kg.Padding = [5 5 5 5]; kg.RowHeight = {24, 24, 24}; kg.ColumnWidth = {145, '1x'};
            
            lbl = uilabel(kg, 'Text', 'Hub Radius R_hub (m):'); 
            lbl.Tooltip = sprintf('Hub / Central core radius of the Kaplan turbine in meters.');
            lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.RCuboEdit = uieditfield(kg, 'numeric', 'Value', 0.30, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.RCuboEdit.Layout.Row = 1; app.RCuboEdit.Layout.Column = 2;
            
            lbl = uilabel(kg, 'Text', 'Tip Radius R_tip (m):'); 
            lbl.Tooltip = sprintf('Outer peripheral radius (Blade Tip) in meters.');
            lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.RPuntaEdit = uieditfield(kg, 'numeric', 'Value', 0.65, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.RPuntaEdit.Layout.Row = 2; app.RPuntaEdit.Layout.Column = 2;
            
            lbl = uilabel(kg, 'Text', 'Axial Length L_z (m):'); 
            lbl.Tooltip = sprintf('Projected longitudinal/axial length of the runner along the Z-axis.');
            lbl.Layout.Row = 3; lbl.Layout.Column = 1;
            app.LzEdit = uieditfield(kg, 'numeric', 'Value', 0.35); app.LzEdit.Layout.Row = 3; app.LzEdit.Layout.Column = 2;
            
            app.DeriazPanel = uipanel(app.LeftGrid, 'Title', 'Deriaz Geometry', 'FontWeight', 'bold', 'Visible', 'off');
            app.DeriazPanel.Layout.Row = r; app.DeriazPanel.Layout.Column = [1 2];
            dg = uigridlayout(app.DeriazPanel, [4, 2]); dg.RowSpacing = 4; dg.Padding = [5 5 5 5]; dg.RowHeight = {22, 22, 22, 22}; dg.ColumnWidth = {145, '1x'};
            
            lbl = uilabel(dg, 'Text', 'Inner Sph. Rad. Re_int:'); 
            lbl.Tooltip = sprintf('Inner spherical radius for the Deriaz hub dome.');
            lbl.Layout.Row = 1; lbl.Layout.Column = 1;
            app.ReIntEdit = uieditfield(dg, 'numeric', 'Value', 2.00, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.ReIntEdit.Layout.Row = 1; app.ReIntEdit.Layout.Column = 2;
            
            lbl = uilabel(dg, 'Text', 'Outer Sph. Rad. Re_ext:'); 
            lbl.Tooltip = sprintf('Outer spherical radius for the diagonal outer casing.');
            lbl.Layout.Row = 2; lbl.Layout.Column = 1;
            app.ReExtEdit = uieditfield(dg, 'numeric', 'Value', 2.60, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.ReExtEdit.Layout.Row = 2; app.ReExtEdit.Layout.Column = 2;
            
            lbl = uilabel(dg, 'Text', 'Inlet Angle gamma1 (°):'); 
            lbl.Tooltip = sprintf([ ...
                'Inlet Cone Angle (\x03B31 in degrees):\n' ...
                '• Angle of the surface of revolution at the leading edge relative to the axis of rotation.\n' ...
                '• Alters 3D spatial orientation and meridian velocity vector component at inlet.']);
            lbl.Layout.Row = 3; lbl.Layout.Column = 1;
            app.Gamma1Edit = uieditfield(dg, 'numeric', 'Value', 30.0, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.Gamma1Edit.Layout.Row = 3; app.Gamma1Edit.Layout.Column = 2;
            
            lbl = uilabel(dg, 'Text', 'Outlet Angle gamma2 (°):'); 
            lbl.Tooltip = sprintf([ ...
                'Outlet Cone Angle (\x03B32 in degrees):\n' ...
                '• Slope angle of the flow surface at the trailing edge relative to the axis.\n' ...
                '• Controls outlet flow divergence entering the draft tube.']);
            lbl.Layout.Row = 4; lbl.Layout.Column = 1;
            app.Gamma2Edit = uieditfield(dg, 'numeric', 'Value', 60.0, 'ValueChangedFcn', @(~,~) app.validateGeometryFields()); app.Gamma2Edit.Layout.Row = 4; app.Gamma2Edit.Layout.Column = 2;

    % Compute Button (Row 13)
    r = 13;
    app.ComputeBtn = uibutton(app.LeftGrid, 'push', 'Text', ' COMPUTE SOLID 3D DESIGN', 'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.12 0.53 0.90], 'FontColor', [1 1 1], 'ButtonPushedFcn', @(~,~) app.computeTurbine());
    app.ComputeBtn.Layout.Row = r; app.ComputeBtn.Layout.Column = [1 2];
    
    % Export Options Panel (Row 14)
    r = 14;
    app.ExportPanel = uipanel(app.LeftGrid, 'Title', ' Export Manager ', 'FontWeight', 'bold', 'BackgroundColor', [0.95 0.97 0.95]); app.ExportPanel.Layout.Row = r; app.ExportPanel.Layout.Column = [1 2];
    exg = uigridlayout(app.ExportPanel, [4, 2]); exg.RowSpacing = 4; exg.Padding = [6 4 6 4]; exg.RowHeight = {22, 22, 30, 30}; exg.ColumnWidth = {115, '1x'};
    lbl = uilabel(exg, 'Text', 'Export Geometry:'); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
    app.ExportTypeDropDown = uidropdown(exg, 'Items', {'Solid Blade (Full)', 'Mean Surface Only'}); app.ExportTypeDropDown.Layout.Row = 1; app.ExportTypeDropDown.Layout.Column = 2;
    lbl = uilabel(exg, 'Text', 'CAD Format:'); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
    app.ExportFormatDropDown = uidropdown(exg, 'Items', {'STL (*.stl)', 'IGES (*.igs / *.iges)'}); app.ExportFormatDropDown.Layout.Row = 2; app.ExportFormatDropDown.Layout.Column = 2;
    app.ExportCADBtn = uibutton(exg, 'push', 'Text', ' Export CAD Geometry', 'FontWeight', 'bold', 'Enable', 'off', 'BackgroundColor', [0.2 0.65 0.3], 'FontColor', [1 1 1], 'ButtonPushedFcn', @(~,~) app.exportCAD());
    app.ExportCADBtn.Layout.Row = 3; app.ExportCADBtn.Layout.Column = [1 2];
    app.ExportExcelBtn = uibutton(exg, 'push', 'Text', ' Export Blade Angles (Excel)', 'FontWeight', 'bold', 'Enable', 'off', 'BackgroundColor', [0.85 0.45 0.1], 'FontColor', [1 1 1], 'ButtonPushedFcn', @(~,~) app.exportExcel());
    app.ExportExcelBtn.Layout.Row = 4; app.ExportExcelBtn.Layout.Column = [1 2];

    %% ====================================================================
    %% PESTAÑA 2: PERFILES HIDRODINÁMICOS & RESOLUCIÓN
    %% ====================================================================
    gridTab2 = uigridlayout(app.TabHydro, [1, 1]); gridTab2.Padding = [0 0 0 0];
    
    app.HydroScrollPanel = uipanel(gridTab2, 'Title', ' Hydrofoil & Mesh Parameters ', ...
        'FontWeight', 'bold', 'FontSize', 11, 'Scrollable', 'on');
    
    container2 = uipanel(app.HydroScrollPanel, 'BorderType', 'none');
    container2.Position = [0 0 420 400]; % Altura compacta sin espacio sobrante
    
    app.HydroGrid = uigridlayout(container2, [3, 1]);
    app.HydroGrid.RowHeight = {'fit', 'fit', 38};
    app.HydroGrid.RowSpacing = 10;
    
    % 1. Airfoil Design Panel
    app.AirfoilPanel = uipanel(app.HydroGrid, 'Title', 'Hydrofoil Profile Design', 'FontWeight', 'bold', 'BackgroundColor', [0.98 0.98 1.0]);
    app.AirfoilPanel.Layout.Row = 1;
    ag = uigridlayout(app.AirfoilPanel, [4, 2]); ag.RowSpacing = 4; ag.Padding = [5 5 5 5]; ag.RowHeight = {'fit', 'fit', 'fit', 'fit'}; ag.ColumnWidth = {145, '1x'};
    
    lbl = uilabel(ag, 'Text', 'Hydrofoil Profile:', 'FontWeight', 'bold'); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
    lbl.Tooltip = sprintf([ ...
    'Hydrofoil Formulations:\n' ...
    '1. NACA 00XX: Uncambered (yc=0) | Standard NACA 4-digit thickness yt(x).\n' ...
    '2. Customized: Parametric m & p interpolation from hub to tip (m_factor=(1-r*)^1.5).\n' ...
    '   Piecewise parabolic yc(x) with standard yt(x).\n' ...
    '3. Reversible: Pure symmetric ellipse (yc=0) | yt = t_c*sqrt(x*(1-x)).\n' ...
    '4. Anti-Cavitation: High forward camber | yt = 2.6896*t_c*x*(1-x)^1.5, yc = (yt/2)*m_factor.\n' ...
    '5. Low-Torque S-Camber: Reflexed camber | yc = 0.8*x*(1-x)*(0.5-x)*m_factor.\n\n' ...
    'Note: Relative thickness (t_c) scales with Hub-to-Tip Ratio.']);
    app.NACADropDown = uidropdown(ag, 'Items', { ...
    'NACA 00XX (Standard Symmetric)', ...
    'Customized (4-Digit NACA Series)', ...
    'Reversible Hydrofoil (Pump-Turbine)', ...
    'Anti-Cavitation (Flat Pressure)', ...
    'Low-Torque S-Camber'}, ...
    'Value', 'Reversible Hydrofoil (Pump-Turbine)', ...
    'ValueChangedFcn', @(~,~) app.onProfileTypeChange());
    app.NACADropDown.Layout.Row = 1; app.NACADropDown.Layout.Column = 2;
    
    lbl = uilabel(ag, 'Text', 'Max Rel. Thickness (t/c):'); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
     lbl.Tooltip = sprintf([ ...
                'Maximum Relative Airfoil Thickness (t/c):\n' ...
                '• Non-dimensional ratio between max thickness (t) and chord (c).\n' ...
                '• Higher thickness increases structural stiffness at the hub, but raises drag and flow separation risk.']);
            
    app.ThicknessEdit = uieditfield(ag, 'numeric', 'Value', 0.085, 'Limits', [0.01 0.40]);
    app.ThicknessEdit.Layout.Row = 2; app.ThicknessEdit.Layout.Column = 2;

    % Fila 3: Hub to Tip Thickness Ratio
lbl = uilabel(ag, 'Text', 'Hub to Tip Thickness Ratio:'); 
lbl.Layout.Row = 3; lbl.Layout.Column = 1;
lbl.Tooltip = sprintf([ ...
    'Hub to Tip Relative Thickness Ratio (t_tip / t_hub):\n' ...
    '• Ratio between the profile normalized relative thickness at the blade tip and at the hub/root.\n' ...
    '• A value of 0.65 means the tip retains 65%% of the hub relative thickness (35%% taper loss).\n' ...
    '• Reduces structural stress from centrifugal forces and improves hydrodynamic performance near the tip.']);

app.HubToTipRatioEdit = uieditfield(ag, 'numeric', ...
    'Value', 0.65, ...
    'Limits', [0.10 1.00], ...
    'ValueDisplayFormat', '%.2f');
app.HubToTipRatioEdit.Layout.Row = 3; 
app.HubToTipRatioEdit.Layout.Column = 2;

% 2. Añadir sub-panel para parámetros Customized en la Fila 4 de AirfoilPanel
app.CustomPanel = uipanel(ag, 'Title', 'Customized (4-Digit NACA Series)', ...
    'FontWeight', 'bold', 'Visible', 'off'); % Oculto por defecto
app.CustomPanel.Layout.Row = 4; app.CustomPanel.Layout.Column = [1 2];

cg = uigridlayout(app.CustomPanel, [2, 4]);
cg.RowSpacing = 3; cg.Padding = [4 4 4 4]; 
cg.RowHeight = {22, 22}; cg.ColumnWidth = {'fit', '1x', 'fit', '1x'};

% Hub m & p
lbl = uilabel(cg, 'Text', 'm_hub (%):'); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
lbl.Tooltip = 'Max camber at hub as % of chord (e.g. 2 for 2%).';
app.MHubEdit = uieditfield(cg, 'numeric', 'Value', 2.0, 'Limits', [-9 9], 'ValueDisplayFormat', '%.1f');
app.MHubEdit.Layout.Row = 1; app.MHubEdit.Layout.Column = 2;

lbl = uilabel(cg, 'Text', 'p_hub (x10%):'); lbl.Layout.Row = 1; lbl.Layout.Column = 3;
lbl.Tooltip = 'Location of max camber at hub (e.g. 4 for 40% chord).';
app.PHubEdit = uieditfield(cg, 'numeric', 'Value', 4.0, 'Limits', [1 9], 'ValueDisplayFormat', '%.1f');
app.PHubEdit.Layout.Row = 1; app.PHubEdit.Layout.Column = 4;

% Tip m & p
lbl = uilabel(cg, 'Text', 'm_tip (%):'); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
lbl.Tooltip = 'Max camber at tip as % of chord (0 = symmetric).';
app.MTipEdit = uieditfield(cg, 'numeric', 'Value', 0.0, 'Limits', [-9 9], 'ValueDisplayFormat', '%.1f');
app.MTipEdit.Layout.Row = 2; app.MTipEdit.Layout.Column = 2;

lbl = uilabel(cg, 'Text', 'p_tip (x10%):'); lbl.Layout.Row = 2; lbl.Layout.Column = 3;
lbl.Tooltip = 'Location of max camber at tip (e.g. 4 for 40% chord).';
app.PTipEdit = uieditfield(cg, 'numeric', 'Value', 4.0, 'Limits', [1 9], 'ValueDisplayFormat', '%.1f');
app.PTipEdit.Layout.Row = 2; app.PTipEdit.Layout.Column = 4;
    
    % 2. Advanced Options Panel (Mesh Resolution)
    app.AdvPanel = uipanel(app.HydroGrid, 'Title', 'Advanced Options (Mesh Resolution)', 'FontWeight', 'bold');
    app.AdvPanel.Layout.Row = 2;
    advg = uigridlayout(app.AdvPanel, [2, 2]); advg.RowSpacing = 3; advg.Padding = [5 3 5 3]; advg.RowHeight = {20, 20}; advg.ColumnWidth = {'fit', '1x'};
    
    lbl = uilabel(advg, 'Text', 'Streamlines (N_radii):'); lbl.Layout.Row = 1; lbl.Layout.Column = 1;
     lbl.Tooltip = sprintf([ ...
                'Spanwise Mesh Resolution (N_radii):\n' ...
                '• Number of evaluated radial streamlines from Hub to Tip.\n' ...
                '• Higher density (>50) generates intermediate cross-sections with higher geometric precision for CAD/STL export.']);
           
    app.NRadiosEdit = uieditfield(advg, 'numeric', 'Value', 100, 'Limits', [5 200], 'RoundFractionalValues', 'on'); app.NRadiosEdit.Layout.Row = 1; app.NRadiosEdit.Layout.Column = 2;
    
    lbl = uilabel(advg, 'Text', 'Chord Stations (dz/dgamma/ds):'); lbl.Layout.Row = 2; lbl.Layout.Column = 1;
    lbl.Tooltip = sprintf([ ...
                'Chordwise Profile Resolution (dz/d\x03B3/ds):\n' ...
                '• Discretization points along the chord from leading edge to trailing edge.\n' ...
                '• High value (>100) resolves the NACA nose curvature smoothly and prevents polygonal faceted artifacts.']);
           
    app.NCuerdaEdit = uieditfield(advg, 'numeric', 'Value', 200, 'Limits', [15 500], 'RoundFractionalValues', 'on'); app.NCuerdaEdit.Layout.Row = 2; app.NCuerdaEdit.Layout.Column = 2;

    % 3. Compute Button
    app.ComputeBtn2 = uibutton(app.HydroGrid, 'push', 'Text', ' COMPUTE SOLID 3D DESIGN', ...
        'FontWeight', 'bold', 'FontSize', 11, 'BackgroundColor', [0.12 0.53 0.90], ...
        'FontColor', [1 1 1], 'ButtonPushedFcn', @(~,~) app.computeTurbine());
    app.ComputeBtn2.Layout.Row = 3;
    %% ====================================================================
    %% 3. RIGHT PANEL (Compartido para ambas pestañas en la Columna 2)
    %% ====================================================================
    app.RightMainGrid = uigridlayout(app.MainGrid, [2, 1]);
    app.RightMainGrid.Layout.Row = 2; 
    app.RightMainGrid.Layout.Column = 2;
    app.RightMainGrid.RowHeight = {'1x', 160};
    
    app.RendersGrid = uigridlayout(app.RightMainGrid, [1, 2]);
    app.RendersGrid.ColumnWidth = {'1x', '1x'}; app.RendersGrid.Padding = [0 0 0 0];
    
    MeanPanel = uipanel(app.RendersGrid, 'Title', 'Visualization A: Multiblade Mean Surface', 'FontWeight', 'bold');
    gridMean = uigridlayout(MeanPanel, [1, 1]);
    app.Axes3D_Mid = uiaxes(gridMean); title(app.Axes3D_Mid, 'Multiblade Mean Surface'); axis(app.Axes3D_Mid, 'equal'); grid(app.Axes3D_Mid, 'on'); view(app.Axes3D_Mid, -35, 30);
    app.ColorbarMid = colorbar(app.Axes3D_Mid);
    app.ColorbarMid.Label.String = 'Radius (m)';
    
    SolidPanel = uipanel(app.RendersGrid, 'Title', 'Visualization B: Solid Runner (Airfoil Profiles)', 'FontWeight', 'bold', 'BackgroundColor', [0.96 0.98 1.0]);
    gridSolid = uigridlayout(SolidPanel, [1, 1]);
    app.Axes3D_Solid = uiaxes(gridSolid); title(app.Axes3D_Solid, 'Solid Runner Render'); axis(app.Axes3D_Solid, 'equal'); grid(app.Axes3D_Solid, 'on'); view(app.Axes3D_Solid, -35, 30);
    app.ColorbarSolid = colorbar(app.Axes3D_Solid);
    app.ColorbarSolid.Label.String = 'Radius (m)';
    
    app.ResultsTable = uitable(app.RightMainGrid, 'ColumnName', {'Analyzed Parameter', 'Computed Value'}, ...
        'RowName', {}, 'ColumnWidth', {300, '1x'}, 'FontName', 'Segoe UI', 'FontSize', 11, 'BackgroundColor', [1 1 1; 0.96 0.96 0.98]);

    %% 4. STATUS BAR (fila inferior, spanning ambas columnas)
    app.StatusBarPanel = uipanel(app.MainGrid, 'BorderType', 'line', 'BackgroundColor', [0.97 0.97 0.98]);
    app.StatusBarPanel.Layout.Row = 3; app.StatusBarPanel.Layout.Column = [1 2];
    statusGrid = uigridlayout(app.StatusBarPanel, [1, 2]);
    statusGrid.Padding = [10 2 10 2]; statusGrid.ColumnWidth = {'1x', 'fit'};
    app.StatusLabel = uilabel(statusGrid, 'Text', 'Ready. Set your parameters and press COMPUTE.', ...
        'FontColor', [0.35 0.35 0.35], 'FontSize', 10);
    app.StatusLabel.Layout.Column = 1;
    app.LastComputedLabel = uilabel(statusGrid, 'Text', '', 'FontColor', [0.55 0.55 0.55], 'FontSize', 10, ...
        'HorizontalAlignment', 'right');
    app.LastComputedLabel.Layout.Column = 2;
end
        
        function onProfileTypeChange(app)
    if strcmp(app.NACADropDown.Value, 'Customized (4-Digit NACA Series)')
        app.CustomPanel.Visible = 'on';
    else
        app.CustomPanel.Visible = 'off';
    end
end
        function onTurbineTypeChange(app)
            isKaplan = strcmp(app.TurbineTypeDropDown.Value, 'Kaplan (Axial)');
            if isKaplan
                app.KaplanPanel.Visible = 'on'; app.DeriazPanel.Visible = 'off';
                app.RPMEdit.Value = 450; app.Q0Edit.Value = 12; app.HnEdit.Value = 15;
                app.EtaHEdit.Value = 0.90; app.EtaVEdit.Value = 0.96; app.EtaOEdit.Value = 0.98; app.SigmaEdit.Value = 1.25;
                app.ThicknessEdit.Value = 0.085;
                app.NACADropDown.Value = 'NACA 00XX (Standard Symmetric)';
            else
                app.KaplanPanel.Visible = 'off'; app.DeriazPanel.Visible = 'on';
                app.RPMEdit.Value = 150; app.Q0Edit.Value = 110; app.HnEdit.Value = 60;
                app.EtaHEdit.Value = 0.91; app.EtaVEdit.Value = 0.97; app.EtaOEdit.Value = 0.98; app.SigmaEdit.Value = 1.40;
                app.ThicknessEdit.Value = 1.05;
                app.NACADropDown.Value = 'Reversible Hydrofoil (Pump-Turbine)';
            end
        end
        
        function p = evaluateInterpolation(~, typeStr, t)
            switch typeStr
                case 'Cubic (Standard)'; p = 3*(t.^2) - 2*(t.^3);
                case 'Linear (Uniform)'; p = t;
                case 'Cosine (Smooth)'; p = 0.5 * (1 - cos(pi * t));
                case 'Inlet Loaded (Attack)'; p = 1 - (1 - t).^2;
                case 'Outlet Loaded (Discharge)'; p = t.^2;
                otherwise; p = 3*(t.^2) - 2*(t.^3);
            end
        end
        
        function [Nx, Ny, Nz] = computeThicknessDirection(app, X, Y, Z)
            % Thickness direction used to offset the extrados/intrados away
            % from the mean surface.
            %
            % Instead of using the FULL normal of the mean surface
            % (surfnorm, which mixes chordwise curvature with the blade's
            % twist rate between radial stations), a direction is built
            % that lives within the local section plane (chord +
            % circumferential), matching how 2D airfoil sections are
            % classically defined when stacked along radial stations. This
            % prevents the thickness from "dragging" a twist component
            % that grows proportionally with thickness and makes the blade
            % appear to lean sideways / penetrate the inner radius as it
            % gets thicker.
            %
            % Only affects how the SOLID (extrados/intrados) is generated
            % from the mean surface; the mean surface itself (backbone) is
            % NOT modified.

            % NOTE: MATLAB's gradient(F) returns [FX, FY] where FX is the
            % gradient along COLUMNS (2nd array dimension) and FY is the
            % gradient along ROWS (1st array dimension) - this is the
            % OPPOSITE order convention to numpy.gradient(), which returns
            % [axis0, axis1] = [rows, columns] first. Our matrices are
            % shaped (N_cuerda, N_radios), i.e. rows = chordwise,
            % columns = spanwise, so the outputs are swapped here
            % (dXdv, dXdu instead of dXdu, dXdv) to correctly end up with
            % dXdu = chordwise tangent and dXdv = spanwise tangent, exactly
            % matching the Python/numpy version's semantics.
            [dXdv, dXdu] = gradient(X);
            [dYdv, dYdu] = gradient(Y);
            [dZdv, dZdu] = gradient(Z);

            % Chordwise tangent, normalized
            Tu_norm = sqrt(dXdu.^2 + dYdu.^2 + dZdu.^2);
            Tu_norm(Tu_norm == 0) = 1.0;
            Tux = dXdu ./ Tu_norm; Tuy = dYdu ./ Tu_norm; Tuz = dZdu ./ Tu_norm;

            % Local circumferential direction (tangent to the circle of
            % radius sqrt(X^2+Y^2) centered on the Z axis) - valid for both
            % axial (Kaplan) and conical (Deriaz) geometry, since both are
            % surfaces of revolution about the Z axis.
            r_cyl = sqrt(X.^2 + Y.^2);
            r_safe = r_cyl;
            r_safe(r_safe < 1e-9) = 1.0;
            ex = -Y ./ r_safe; ey = X ./ r_safe; ez = zeros(size(X));

            dotp = ex .* Tux + ey .* Tuy + ez .* Tuz;
            Nx_raw = ex - dotp .* Tux;
            Ny_raw = ey - dotp .* Tuy;
            Nz_raw = ez - dotp .* Tuz;
            N_norm = sqrt(Nx_raw.^2 + Ny_raw.^2 + Nz_raw.^2);

            % Fallback to the classic surface normal (equivalent to
            % surfnorm, via cross(Tu,Tv)) in the degenerate case where the
            % circumferential direction ends up nearly parallel to the
            % chordwise tangent.
            Fx = Tuy .* dZdv - Tuz .* dYdv;
            Fy = Tuz .* dXdv - Tux .* dZdv;
            Fz = Tux .* dYdv - Tuy .* dXdv;
            F_norm = sqrt(Fx.^2 + Fy.^2 + Fz.^2);
            F_norm(F_norm == 0) = 1.0;
            Fx = Fx ./ F_norm; Fy = Fy ./ F_norm; Fz = Fz ./ F_norm;

            degenerate = N_norm < 1e-6;
            N_norm_safe = N_norm;
            N_norm_safe(N_norm_safe == 0) = 1.0;

            Nx = Nx_raw ./ N_norm_safe;
            Ny = Ny_raw ./ N_norm_safe;
            Nz = Nz_raw ./ N_norm_safe;

            Nx(degenerate) = Fx(degenerate);
            Ny(degenerate) = Fy(degenerate);
            Nz(degenerate) = Fz(degenerate);
        end

        function [yc, yt] = generateHydroProfile(app, profileType, n_points, t_c_base, i_radio, N_radios)
    x_norm = linspace(0, 1, n_points);
    
    % 1. Radio adimensional r_star (0 en Hub / Re_int, 1 en Tip / Re_ext)
    if N_radios > 1
        r_star = (i_radio - 1) / (N_radios - 1);
    else
        r_star = 0;
    end
    
    % 2. Atenuación radial del espesor relativo (tc) y de la curvatura (m_factor)
    %  la punta conserva ~65% del grosor relativo del cubo
    hubToTipRatio = app.HubToTipRatioEdit.Value;
    t_c = t_c_base * (1 - (1 - hubToTipRatio) * r_star);
    % Factor de Camber: disminuye suavemente de 1 (100%) a 0 (0% = simétrico en la punta)
    m_factor = (1 - r_star)^1.5; 

    if contains(profileType, 'Reversible Hydrofoil')
        % Perfil Reversible Simétrico (Ecuación Elíptica)
        yc = zeros(size(x_norm));
        yt = t_c * sqrt(x_norm .* (1 - x_norm));
        
    elseif contains(profileType, 'Anti-Cavitation')
        % Perfil Göttingen-type Anti-Cavitación (Camber atenuado hacia la punta)
        yt = (2.6896 * t_c) * x_norm .* (1 - x_norm).^1.5;
        yc = (yt / 2) * m_factor; 
        
    elseif contains(profileType, 'Low-Torque S-Camber')
        % Perfil Reflex S-Camber (S-Camber reducido progresivamente)
        yc = 0.8 * x_norm .* (1 - x_norm) .* (0.5 - x_norm) * m_factor;
        yt = (t_c / 0.2) * (0.2969*sqrt(x_norm) - 0.1260*x_norm - 0.3516*x_norm.^2 + 0.2843*x_norm.^3 - 0.1015*x_norm.^4);
        
    elseif contains(profileType, 'Customized (4-Digit NACA Series)')
    % Lectura de valores ingresados en % (ej. 2 -> 0.02, 4 -> 0.4)
    m_hub_val = app.MHubEdit.Value / 100;
    p_hub_val = app.PHubEdit.Value / 10;
    
    m_tip_val = app.MTipEdit.Value / 100;
    p_tip_val = app.PTipEdit.Value / 10;
    
    % Interpolación radial desde cubo hasta punta usando la atenuación m_factor:
    % En r_star = 0 (cubo): m = m_hub_val
    % En r_star = 1 (punta): m = m_tip_val
    m = m_tip_val + (m_hub_val - m_tip_val) * m_factor;
    p = p_tip_val + (p_hub_val - p_tip_val) * m_factor;
    
    % Seguridad para evitar divisiones por cero si p o m son 0
    p = max(p, 0.05); 
    
    yc = zeros(size(x_norm));
    if abs(m) > 0
        for k = 1:length(x_norm)
            if x_norm(k) < p
                yc(k) = (m / p^2) * (2*p*x_norm(k) - x_norm(k)^2);
            else
                yc(k) = (m / (1-p)^2) * ((1 - 2*p) + 2*p*x_norm(k) - x_norm(k)^2);
            end
        end
    end
    
    % Espesor de 4 dígitos NACA clásico escalado con t_c
    yt = (t_c / 0.2) * (0.2969*sqrt(x_norm) - 0.1260*x_norm - 0.3516*x_norm.^2 + 0.2843*x_norm.^3 - 0.1015*x_norm.^4); 
    else
        % NACA 00XX / Simétrico por defecto (solo atenúa el espesor)
        yc = zeros(size(x_norm));
        yt = (t_c / 0.2) * (0.2969*sqrt(x_norm) - 0.1260*x_norm - 0.3516*x_norm.^2 + 0.2843*x_norm.^3 - 0.1015*x_norm.^4);
    end
end
        
        function computeTurbine(app)
            
            app.StatusLabel.Text = 'Computing turbine geometry...'; app.StatusLabel.FontColor = [0.10 0.40 0.75]; drawnow;
            dlgProgress = uiprogressdlg(app.UIFigure, 'Title', 'Computing Turbine Geometry', ...
                'Message', 'Initializing hydraulic model...', 'Indeterminate', 'off', 'Value', 0.05, 'Cancelable', 'off');
            cleanupDlg = onCleanup(@() close(dlgProgress));
            
            RPM = app.RPMEdit.Value; Q0 = app.Q0Edit.Value; Hn = app.HnEdit.Value; g = app.gEdit.Value;
            eta_h = app.EtaHEdit.Value; eta_v = app.EtaVEdit.Value; eta_o = app.EtaOEdit.Value;
            sigma_target = app.SigmaEdit.Value; interpType = app.InterpDropDown.Value;
            rotSign = strcmp(app.RotationDropDown.Value, 'Counter-Clockwise (Standard)') * 2 - 1;
            
            N_radios = app.NRadiosEdit.Value; N_cuerda = app.NCuerdaEdit.Value;
            eta_t = eta_h * eta_v * eta_o; omega = (2 * pi * RPM) / 60;
            Q_real = Q0 * eta_v; H_inf = Hn * eta_h;
            nq = RPM * sqrt(Q0) / ((g*Hn)^(3/4));
            
            isKaplan = strcmp(app.TurbineTypeDropDown.Value, 'Kaplan (Axial)');
            
            X_mid = zeros(N_cuerda, N_radios); Y_mid = zeros(N_cuerda, N_radios); Z_mid = zeros(N_cuerda, N_radios);
            b1_vec = zeros(1, N_radios); b2_vec = zeros(1, N_radios);
            
            if isKaplan
                R_cubo = app.RCuboEdit.Value; R_punta = app.RPuntaEdit.Value; L_z = app.LzEdit.Value;
                if R_cubo >= R_punta
                    app.StatusLabel.Text = 'Error: R_hub must be smaller than R_tip.'; app.StatusLabel.FontColor = [0.75 0.15 0.15];
                    uialert(app.UIFigure, 'Geometric bounds error.', 'Error'); return;
                end
                R_m = sqrt((R_punta^2 + R_cubo^2) / 2);
                z_vec = linspace(0, -L_z, N_cuerda); r_vec = linspace(R_cubo, R_punta, N_radios);
                Area_paso = pi * (R_punta^2 - R_cubo^2); V_z = Q_real / Area_paso;
                
                for i = 1:N_radios
                    r = r_vec(i); U = omega * r; V_theta1 = (g * H_inf) / (omega * r);

                    if V_theta1 >= U
                        app.StatusLabel.Text = 'Error: Physical boundary instability detected (see dialog).'; app.StatusLabel.FontColor = [0.75 0.15 0.15];
                        uialert(app.UIFigure, sprintf('Physical boundary instability at r=%.2fm: V_theta1 (%.2f m/s) >= U (%.2f m/s). Increase RPM or decrease head.', r, V_theta1, U), 'Physical Limit Error');
                        return;
                    end

                    beta1 = atan2(V_z, (U - V_theta1)); beta2 = atan2(V_z, U);
                    b1_vec(i) = rad2deg(beta1); b2_vec(i) = rad2deg(beta2);
                    t_dim = abs(z_vec) / L_z;
                    polinomio = app.evaluateInterpolation(interpType, t_dim);
                    beta_z = beta1 + (beta2 - beta1) .* polinomio;
                    theta_rel = 0;
                    for j = 1:N_cuerda
                        if j > 1
                            dz = abs(z_vec(j) - z_vec(j-1)); 
                            theta_rel = theta_rel - rotSign * (cot(beta_z(j)) / r) * dz;
                        end
                        X_mid(j, i) = r * cos(theta_rel); Y_mid(j, i) = r * sin(theta_rel); Z_mid(j, i) = z_vec(j);
                    end
                end
                [~, mid_ref_R] = min(abs(r_vec - R_m));
                dx = diff(X_mid(:, mid_ref_R)); dy = diff(Y_mid(:, mid_ref_R)); dz = diff(Z_mid(:, mid_ref_R));
                L_chord_reference = sum(sqrt(dx.^2 + dy.^2 + dz.^2));
                Z_optimo = max(3, min(round((2 * pi * R_m) / (L_chord_reference / sigma_target)), 12));
                rm_label = 'Mean Hydraulic Radius (R_m)'; rm_val = sprintf('%.3f m', R_m);
                R_color = repmat(r_vec, N_cuerda, 1); app.RadiusVec = r_vec;
            else
                Re_int = app.ReIntEdit.Value; Re_ext = app.ReExtEdit.Value; gamma1 = deg2rad(app.Gamma1Edit.Value); gamma2 = deg2rad(app.Gamma2Edit.Value);
                if Re_int >= Re_ext || gamma1 >= gamma2
                    app.StatusLabel.Text = 'Error: check spherical radii or slope angle bounds.'; app.StatusLabel.FontColor = [0.75 0.15 0.15];
                    uialert(app.UIFigure, 'Geometric bounds error.', 'Error'); return;
                end
                Re_medio = (Re_ext - Re_int) / log(Re_ext / Re_int);
                Re_vec = linspace(Re_int, Re_ext, N_radios); gamma_vec = linspace(gamma1, gamma2, N_cuerda);
                RC_surf = zeros(N_cuerda, N_radios);
                
                for i = 1:N_radios
                    Re = Re_vec(i); rc1 = Re * cos(gamma1); U1 = omega * rc1;
                    Vm1 = Q_real / (2 * pi * Re * cos(gamma1) * (Re_ext - Re_int)); Vtheta1 = (g * H_inf) / U1;
                    if Vtheta1 >= U1
                        app.StatusLabel.Text = 'Error: Physical boundary instability detected (see dialog).'; app.StatusLabel.FontColor = [0.75 0.15 0.15];
                        uialert(app.UIFigure, sprintf('Physical boundary instability at Re=%.2fm: V_theta1 (%.2f m/s) >= U1 (%.2f m/s). Increase RPM or decrease head.', Re, Vtheta1, U1), 'Physical Limit Error');
                        return;
                    end
                    beta1 = atan2(Vm1, (U1 - Vtheta1));
                    rc2 = Re * cos(gamma2); U2 = omega * rc2;
                    Vm2 = Q_real / (2 * pi * Re * cos(gamma2) * (Re_ext - Re_int)); beta2 = atan2(Vm2, U2);
                    b1_vec(i) = rad2deg(beta1); b2_vec(i) = rad2deg(beta2);
                    
                    polinomio = app.evaluateInterpolation(interpType, (gamma_vec - gamma1) / (gamma2 - gamma1));
                    beta_gamma = beta1 + (beta2 - beta1) .* polinomio;
                    theta_rel = 0;
                    for j = 1:N_cuerda
                        gamma_actual = gamma_vec(j);
                        if j > 1
                            theta_rel = theta_rel - rotSign * (cot(beta_gamma(j)) / cos(gamma_actual)) * (gamma_vec(j) - gamma_vec(j-1));
                        end
                        rc_local = Re * cos(gamma_actual); RC_surf(j, i) = rc_local;
                        X_mid(j, i) = rc_local * cos(theta_rel); Y_mid(j, i) = rc_local * sin(theta_rel); Z_mid(j, i) = -Re * sin(gamma_actual);
                    end
                end
                [~, mid_ref_R] = min(abs(Re_vec - Re_medio));
                dx = diff(X_mid(:, mid_ref_R)); dy = diff(Y_mid(:, mid_ref_R)); dz = diff(Z_mid(:, mid_ref_R));
                L_chord_reference = sum(sqrt(dx.^2 + dy.^2 + dz.^2));
                rc_promedio_medio = mean(RC_surf(:, mid_ref_R));
                Z_optimo = max(4, min(round((2 * pi * rc_promedio_medio) / (L_chord_reference / sigma_target)), 12));
                rm_label = 'Mean Spherical Radius (Re_mean)'; rm_val = sprintf('%.3f m', Re_medio);
                R_color = RC_surf; app.RadiusVec = Re_vec;
            end
            
            app.Beta1_deg = b1_vec; app.Beta2_deg = b2_vec;
            app.Z_optimo_current = Z_optimo; app.RC_grid = R_color;
            app.X_mid = X_mid; app.Y_mid = Y_mid; app.Z_mid = Z_mid;
            
            if isKaplan
                app.ColorbarMid.Label.String = 'Radius (m)'; app.ColorbarSolid.Label.String = 'Radius (m)';
            else
                app.ColorbarMid.Label.String = 'Spherical Radius (m)'; app.ColorbarSolid.Label.String = 'Spherical Radius (m)';
            end
            dlgProgress.Value = 0.40; dlgProgress.Message = 'Generating solid airfoil profile (extrados/intrados)...';
            
            %% Correct 3D Hydrofoil Profile Generation
            nacaStr = char(app.NACADropDown.Value);
            t_rel_input = app.ThicknessEdit.Value; 
            
            s_backbone = zeros(N_cuerda, N_radios);
            dx_m = diff(X_mid, 1, 1); dy_m = diff(Y_mid, 1, 1); dz_m = diff(Z_mid, 1, 1);
            ds_m = sqrt(dx_m.^2 + dy_m.^2 + dz_m.^2);
            s_backbone(2:end, :) = cumsum(ds_m, 1);
            chord_lengths = s_backbone(end, :); 
            
            c_hub = chord_lengths(1);
            t_abs_ref = t_rel_input * c_hub; 
            
            X_sol_ext = zeros(N_cuerda, N_radios); Y_sol_ext = zeros(N_cuerda, N_radios); Z_sol_ext = zeros(N_cuerda, N_radios);
            X_sol_int = zeros(N_cuerda, N_radios); Y_sol_int = zeros(N_cuerda, N_radios); Z_sol_int = zeros(N_cuerda, N_radios);
            
            [Nx, Ny, Nz] = app.computeThicknessDirection(X_mid, Y_mid, Z_mid);
            
            for i = 1:N_radios
                c_i = chord_lengths(i); 
                t_rel_local = t_abs_ref / c_i; 
                
                % Llamada a la nueva función
                % CAMBIO: Añadidos 'i' y 'N_radios' al final de la llamada
                [yc_base, yt_base] = app.generateHydroProfile(nacaStr, N_cuerda, t_rel_local, i, N_radios);
                
                camber_offset = (yc_base(:)) * c_i; 
                thick_offset  = (yt_base(:))  * c_i; 
                
                nx_i = Nx(:, i); ny_i = Ny(:, i); nz_i = Nz(:, i);
                
                offset_ext = camber_offset + thick_offset;
                offset_int = camber_offset - thick_offset;
                
                % Se ha corregido offset_ext .* ny_i (tenías nx_i por error en Y_sol_ext)
                X_sol_ext(:, i) = X_mid(:, i) + offset_ext .* nx_i;
                Y_sol_ext(:, i) = Y_mid(:, i) + offset_ext .* ny_i; 
                Z_sol_ext(:, i) = Z_mid(:, i) + offset_ext .* nz_i;
                
                X_sol_int(:, i) = X_mid(:, i) + offset_int .* nx_i;
                Y_sol_int(:, i) = Y_mid(:, i) + offset_int .* ny_i;
                Z_sol_int(:, i) = Z_mid(:, i) + offset_int .* nz_i;
            end
            
            app.CapsX = { [X_sol_ext(1,:); X_sol_int(1,:)], [X_sol_ext(end,:); X_sol_int(end,:)], ...
                          [X_sol_ext(:,1), X_sol_int(:,1)], [X_sol_ext(:,end), X_sol_int(:,end)] };
            app.CapsY = { [Y_sol_ext(1,:); Y_sol_int(1,:)], [Y_sol_ext(end,:); Y_sol_int(end,:)], ...
                          [Y_sol_ext(:,1), Y_sol_int(:,1)], [Y_sol_ext(:,end), Y_sol_int(:,end)] };
            app.CapsZ = { [Z_sol_ext(1,:); Z_sol_int(1,:)], [Z_sol_ext(end,:); Z_sol_int(end,:)], ...
                          [Z_sol_ext(:,1), Z_sol_int(:,1)], [Z_sol_ext(:,end), Z_sol_int(:,end)] };
            
            app.CapsC = { [R_color(1,:); R_color(1,:)], [R_color(end,:); R_color(end,:)], ...
                          [R_color(:,1), R_color(:,1)], [R_color(:,end), R_color(:,end)] };
            
            app.X_sol_ext = X_sol_ext; app.Y_sol_ext = Y_sol_ext; app.Z_sol_ext = Z_sol_ext;
            app.X_sol_int = X_sol_int; app.Y_sol_int = Y_sol_int; app.Z_sol_int = Z_sol_int;
            
            app.IsComputed = true;
            app.ExportCADBtn.Enable = 'on'; app.ExportExcelBtn.Enable = 'on';
            
            app.ResultsTable.Data = {
                'Airfoil Selection', nacaStr;
                'Total Efficiency (eta_t)', sprintf('%.2f %%', eta_t * 100);
                'Specific Speed (nq)', sprintf('%.2f', nq);
                'Integrated 3D Chord (L_chord_ref)', sprintf('%.3f m', L_chord_reference);
                'Number of Blades (Z)', sprintf('%d', Z_optimo);
                rm_label, rm_val
            };
            
            %% RENDERS
            dlgProgress.Value = 0.80; dlgProgress.Message = 'Rendering 3D geometry...';
            delta_angle = (2 * pi) / Z_optimo;
            cmap = parula(256) * 0.90; metal_color = [0.4 0.4 0.4];
            
            % Render A
            cla(app.Axes3D_Mid); hold(app.Axes3D_Mid, 'on');
            clim(app.Axes3D_Mid, [min(R_color(:)), max(R_color(:))]); colormap(app.Axes3D_Mid, parula(256));
            if isKaplan
                [Xc, Yc, Zc] = cylinder(app.Axes3D_Mid, R_cubo, 50); Zc = Zc * (-L_z);
            else
                [gg_mesh, tg_mesh] = meshgrid(linspace(gamma1, gamma2, 30), linspace(0, 2*pi, 50));
                Xc = Re_int * cos(gg_mesh) .* cos(tg_mesh); Yc = Re_int * cos(gg_mesh) .* sin(tg_mesh); Zc = -Re_int * sin(gg_mesh);
            end
            surf(app.Axes3D_Mid, Xc, Yc, Zc, 'FaceColor', metal_color, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
            title(app.Axes3D_Mid, sprintf('Mean Surface Design (%d Blades)', Z_optimo));
            
            for k = 1:Z_optimo
                ang = (k - 1) * delta_angle;
                surf(app.Axes3D_Mid, X_mid*cos(ang)-Y_mid*sin(ang), X_mid*sin(ang)+Y_mid*cos(ang), Z_mid, R_color, 'FaceColor', 'interp', 'EdgeColor', 'none');
            end
            axis(app.Axes3D_Mid, 'equal'); grid(app.Axes3D_Mid, 'on');
            
            % Render B
            cla(app.Axes3D_Solid); hold(app.Axes3D_Solid, 'on');
            clim(app.Axes3D_Solid, [min(R_color(:)), max(R_color(:))]); colormap(app.Axes3D_Solid, parula(256));
            surf(app.Axes3D_Solid, Xc, Yc, Zc, 'FaceColor', metal_color, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
            title(app.Axes3D_Solid, sprintf('Solid Runner (%s)', nacaStr));
            
            delete(findobj(app.Axes3D_Solid, 'Type', 'light'));
            camlight(app.Axes3D_Solid, 'headlight'); lighting(app.Axes3D_Solid, 'gouraud');

            % --- SISTEMA DE TRIPLE LUZ (ARRIBA + ABAJO + RADIAL LATERAL) ---
            delete(findobj(app.Axes3D_Solid, 'Type', 'light')); % Borra luces previas
            
            % 1. Luz Principal Arriba (Cenital)
            light(app.Axes3D_Solid, 'Position', [0 0 10], 'Style', 'infinite', 'Color', [0.6 0.6 0.6]);
            
            % 2. Luz de Relleno Abajo (Suave)
            light(app.Axes3D_Solid, 'Position', [0 0 -10], 'Style', 'infinite', 'Color', [0.4 0.4 0.4]);
            
            % 3. Luz Radial Lateral (Marca los bordes y caras laterales del perfil)
            light(app.Axes3D_Solid, 'Position', [5 -5 2], 'Style', 'infinite', 'Color', [0.5 0.5 0.5]);
            
            lighting(app.Axes3D_Solid, 'gouraud');
            
            % Ajuste de material suave para evitar destellos
            set(findobj(app.Axes3D_Solid, 'Type', 'surface'), ...
                'AmbientStrength', 0.45, ...  % Luz ambiental balanceada
                'DiffuseStrength', 0.65, ...  % Aumenta la definición de las curvaturas
                'SpecularStrength', 0.05);   % Brillo sutil de acabado metálico
            for k = 1:Z_optimo
                ang = (k - 1) * delta_angle;
                surf(app.Axes3D_Solid, X_sol_ext*cos(ang)-Y_sol_ext*sin(ang), X_sol_ext*sin(ang)+Y_sol_ext*cos(ang), Z_sol_ext, R_color, 'FaceColor', 'interp', 'EdgeColor', 'none', 'AmbientStrength', 0.5);
                surf(app.Axes3D_Solid, X_sol_int*cos(ang)-Y_sol_int*sin(ang), X_sol_int*sin(ang)+Y_sol_int*cos(ang), Z_sol_int, R_color, 'FaceColor', 'interp', 'EdgeColor', 'none', 'AmbientStrength', 0.5);
            end
            
            for cIdx = 1:4
                cx = app.CapsX{cIdx}; cy = app.CapsY{cIdx}; cz = app.CapsZ{cIdx}; cc = app.CapsC{cIdx};
                for k = 1:Z_optimo
                    ang = (k - 1) * delta_angle;
                    surf(app.Axes3D_Solid, cx*cos(ang)-cy*sin(ang), cx*sin(ang)+cy*cos(ang), cz, cc, 'FaceColor', 'interp', 'EdgeColor', 'none', 'AmbientStrength', 0.5);
                end
            end
            
            clim(app.Axes3D_Solid, [min(R_color(:)), max(R_color(:))]); colormap(app.Axes3D_Solid, cmap);



            % --- VISTA DINÁMICA SEGÚN TIPO DE TURBINA ---
            turbineType = char(app.TurbineTypeDropDown.Value); % Obtiene el tipo de turbina
            
            if contains(turbineType, 'Deriaz')
                % Para Deriaz: Inclinación de -30° para apreciar la geometría diagonal/cónica
                axis(app.Axes3D_Solid, 'equal'); grid(app.Axes3D_Solid, 'on'); %view(app.Axes3D_Solid, 95, -27);
            else
                % Para Kaplan (o Axial): Vista de frente pura (0° azimut, 0° elevación/0°)
                axis(app.Axes3D_Solid, 'equal'); grid(app.Axes3D_Solid, 'on'); %view(app.Axes3D_Solid, 0, 0);
            end

            

            
            hold(app.Axes3D_Solid, 'off');
            
            dlgProgress.Value = 1.0; dlgProgress.Message = 'Done.';
            app.StatusLabel.Text = sprintf('Computation complete: %d blades, %s.', Z_optimo, nacaStr);
            app.StatusLabel.FontColor = [0.10 0.55 0.20];
            app.LastComputedLabel.Text = ['Last computed: ' char(datetime('now', 'Format', 'HH:mm:ss'))];
        end
        
function exportCAD(app)
            if ~app.IsComputed
                uialert(app.UIFigure, 'Compute geometry first.', 'Attention'); 
                return; 
            end
            
            isSolid = strcmp(app.ExportTypeDropDown.Value, 'Solid Blade (Full)');
            isSTL = contains(app.ExportFormatDropDown.Value, 'STL');
            
            defaultName = 'TurbineBlade_Export';
            if isSTL
                [file, path] = uiputfile('*.stl', 'Save STL File', [defaultName '.stl']);
            else
                [file, path] = uiputfile('*.igs;*.iges', 'Save IGES File', [defaultName '.igs']);
            end
            if isequal(file, 0), return; end
            
            fullPath = fullfile(path, file);
            
            try
                if isSolid
                    % 1. Extradós (surf2patch devuelve [Faces, Vertices])
                    [F_ext, V_ext] = surf2patch(app.X_sol_ext, app.Y_sol_ext, app.Z_sol_ext, 'triangles');
                    
                    % 2. Intradós - Inversión de normales para apuntar hacia afuera
                    [F_int, V_int] = surf2patch(app.X_sol_int, app.Y_sol_int, app.Z_sol_int, 'triangles');
                    F_int = F_int(:, [1 3 2]); 
                    
                    % 3. Generación de las 4 tapas (LE, TE, Hub, Tip)
                    % Borde de Ataque (LE)
                    [F_le, V_le] = surf2patch( ...
                        [app.X_sol_ext(1,:); app.X_sol_int(1,:)], ...
                        [app.Y_sol_ext(1,:); app.Y_sol_int(1,:)], ...
                        [app.Z_sol_ext(1,:); app.Z_sol_int(1,:)], 'triangles');
                    
                    % Borde de Salida (TE)
                    [F_te, V_te] = surf2patch( ...
                        [app.X_sol_ext(end,:); app.X_sol_int(end,:)], ...
                        [app.Y_sol_ext(end,:); app.Y_sol_int(end,:)], ...
                        [app.Z_sol_ext(end,:); app.Z_sol_int(end,:)], 'triangles');
                    F_te = F_te(:, [1 3 2]);
                    
                    % Raíz / Hub
                    [F_hub, V_hub] = surf2patch( ...
                        [app.X_sol_ext(:,1), app.X_sol_int(:,1)], ...
                        [app.Y_sol_ext(:,1), app.Y_sol_int(:,1)], ...
                        [app.Z_sol_ext(:,1), app.Z_sol_int(:,1)], 'triangles');
                    
                    % Punta / Tip
                    [F_tip, V_tip] = surf2patch( ...
                        [app.X_sol_ext(:,end), app.X_sol_int(:,end)], ...
                        [app.Y_sol_ext(:,end), app.Y_sol_int(:,end)], ...
                        [app.Z_sol_ext(:,end), app.Z_sol_int(:,end)], 'triangles');
                    F_tip = F_tip(:, [1 3 2]);
                    
                    % 4. Consolidación de vértices y desfasaje de índices de caras
                    V_all = [V_ext; V_int; V_le; V_te; V_hub; V_tip];
                    
                    off_ext = 0;
                    off_int = size(V_ext, 1);
                    off_le  = off_int + size(V_int, 1);
                    off_te  = off_le  + size(V_le, 1);
                    off_hub = off_te  + size(V_te, 1);
                    off_tip = off_hub + size(V_hub, 1);
                    
                    F_all = [
                        F_ext + off_ext;
                        F_int + off_int;
                        F_le  + off_le;
                        F_te  + off_te;
                        F_hub + off_hub;
                        F_tip + off_tip
                    ];
                    
                    % 5. Fusión y purga de vértices duplicados para sellado "Watertight"
                    [V_final, ~, ic] = unique(V_all, 'rows');
                    F_final = ic(F_all);
                else
                    % Exportar solo la superficie media
                    [F_final, V_final] = surf2patch(app.X_mid, app.Y_mid, app.Z_mid, 'triangles');
                end
                
                % Escritura de archivo CAD
                if isSTL
                    app.writeSTL_ASCII(fullPath, V_final, F_final);
                else
                    app.writeIGES(fullPath, V_final, F_final);
                end
                
                uialert(app.UIFigure, ['Geometry exported successfully to: ' file], 'Export Success', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ['Export Error: ' ME.message], 'Export Failed');
            end
        end
        
        function writeSTL_ASCII(~, filename, V, F)
            % Generador nativo robusto de archivos STL ASCII
            fid = fopen(filename, 'w');
            if fid == -1, error('Cannot create file. Check write permissions.'); end
            
            fprintf(fid, 'solid HydroTurbineBlade\n');
            
            for i = 1:size(F, 1)
                p1 = V(F(i, 1), :);
                p2 = V(F(i, 2), :);
                p3 = V(F(i, 3), :);
                
                % Cálculo del vector normal por producto cruzado
                normal = cross(p2 - p1, p3 - p1);
                nLen = norm(normal);
                if nLen > 0, normal = normal / nLen; else, normal = [0 0 0]; end
                
                fprintf(fid, '  facet normal %e %e %e\n', normal(1), normal(2), normal(3));
                fprintf(fid, '    outer loop\n');
                fprintf(fid, '      vertex %e %e %e\n', p1(1), p1(2), p1(3));
                fprintf(fid, '      vertex %e %e %e\n', p2(1), p2(2), p2(3));
                fprintf(fid, '      vertex %e %e %e\n', p3(1), p3(2), p3(3));
                fprintf(fid, '    endloop\n');
                fprintf(fid, '  endfacet\n');
            end
            
            fprintf(fid, 'endsolid HydroTurbineBlade\n');
            fclose(fid);
        end
        
        function writeIGES(~, filename, V, F)
            % IGES Triangulated Facet Fallback Writer
            fid = fopen(filename, 'w');
            if fid == -1, error('Cannot create IGES file.'); end
            
            fprintf(fid, 'S      1\n');
            fprintf(fid, 'G240101.000000;1H;1H;1H;1H;38;15;1;1.0;1;1H;1.0;1H;1H;;;G      1\n');
            
            pLine = 1;
            for i = 1:size(F, 1)
                p1 = V(F(i,1), :); p2 = V(F(i,2), :); p3 = V(F(i,3), :);
                fprintf(fid, '116,%f,%f,%f,0,0,0,1.0,0,0;P%7d\n', p1(1), p1(2), p1(3), pLine); pLine = pLine + 1;
                fprintf(fid, '116,%f,%f,%f,0,0,0,1.0,0,0;P%7d\n', p2(1), p2(2), p2(3), pLine); pLine = pLine + 1;
                fprintf(fid, '116,%f,%f,%f,0,0,0,1.0,0,0;P%7d\n', p3(1), p3(2), p3(3), pLine); pLine = pLine + 1;
            end
            
            fprintf(fid, 'T%6d\n', pLine - 1);
            fclose(fid);
        end
        
        function exportExcel(app)
            if ~app.IsComputed
                uialert(app.UIFigure, 'Compute geometry first.', 'Attention'); 
                return; 
            end
            
            [file, path] = uiputfile('*.xlsx', 'Save Excel Report', 'Blade_Angles_Data.xlsx');
            if isequal(file, 0), return; end
            
            fullPath = fullfile(path, file);
            
            try
                T = table(app.RadiusVec', app.Beta1_deg', app.Beta2_deg', ...
                    'VariableNames', {'Radius_m', 'InletAngle_Beta1_deg', 'OutletAngle_Beta2_deg'});
                writetable(T, fullPath);
                uialert(app.UIFigure, ['Excel report saved to: ' file], 'Export Success', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ['Excel Export Error: ' ME.message], 'Export Failed');
            end
        end
        
        %% ====================================================================
        %% PROFESSIONAL EDITION - ADDITIONAL UTILITY METHODS
        %% (UI/UX only - no changes to the underlying hydraulic/geometric math)
        %% ====================================================================
        
        function validateGeometryFields(app)
            % Live visual feedback on the geometry edit fields: light red
            % background when the current values would trigger a geometric
            % bounds error in computeTurbine(), white/default otherwise.
            invalidColor = [1.0 0.90 0.90];
            validColor   = [1 1 1];
            
            if app.RCuboEdit.Value >= app.RPuntaEdit.Value
                app.RCuboEdit.BackgroundColor = invalidColor; app.RPuntaEdit.BackgroundColor = invalidColor;
            else
                app.RCuboEdit.BackgroundColor = validColor; app.RPuntaEdit.BackgroundColor = validColor;
            end
            
            if app.ReIntEdit.Value >= app.ReExtEdit.Value
                app.ReIntEdit.BackgroundColor = invalidColor; app.ReExtEdit.BackgroundColor = invalidColor;
            else
                app.ReIntEdit.BackgroundColor = validColor; app.ReExtEdit.BackgroundColor = validColor;
            end
            
            if app.Gamma1Edit.Value >= app.Gamma2Edit.Value
                app.Gamma1Edit.BackgroundColor = invalidColor; app.Gamma2Edit.BackgroundColor = invalidColor;
            else
                app.Gamma1Edit.BackgroundColor = validColor; app.Gamma2Edit.BackgroundColor = validColor;
            end
        end
        
        function resetView(app)
            % Restores the default camera angle on both 3D renders without
            % recomputing any geometry.
            view(app.Axes3D_Mid, -35, 30);
            view(app.Axes3D_Solid, -35, 30);
            app.StatusLabel.Text = '3D view reset to default angle.';
            app.StatusLabel.FontColor = [0.35 0.35 0.35];
        end
        
        function resetToDefaults(app)
            % Resets every design field to its factory default for the
            % currently selected turbine type, plus the hydrofoil/mesh tab.
            app.RotationDropDown.Value = 'Counter-Clockwise (Standard)';
            app.gEdit.Value = 9.81;
            app.InterpDropDown.Value = 'Cubic (Standard)';
            
            app.onTurbineTypeChange();  % resets RPM/Q0/Hn/eta/sigma/thickness/NACA per type
            
            if strcmp(app.TurbineTypeDropDown.Value, 'Kaplan (Axial)')
                app.RCuboEdit.Value = 0.30; app.RPuntaEdit.Value = 0.65; app.LzEdit.Value = 0.35;
            else
                app.ReIntEdit.Value = 2.00; app.ReExtEdit.Value = 2.60;
                app.Gamma1Edit.Value = 30.0; app.Gamma2Edit.Value = 60.0;
            end
            
            app.HubToTipRatioEdit.Value = 0.65;
            app.MHubEdit.Value = 2.0; app.PHubEdit.Value = 4.0;
            app.MTipEdit.Value = 0.0; app.PTipEdit.Value = 4.0;
            app.NRadiosEdit.Value = 100; app.NCuerdaEdit.Value = 200;
            
            app.ExportTypeDropDown.Value = 'Solid Blade (Full)';
            app.ExportFormatDropDown.Value = 'STL (*.stl)';
            
            app.onProfileTypeChange();
            app.validateGeometryFields();
            app.resetView();
            app.StatusLabel.Text = 'All parameters reset to defaults. Press COMPUTE to regenerate the geometry.';
            app.StatusLabel.FontColor = [0.35 0.35 0.35];
            app.LastComputedLabel.Text = '';
        end
        
        function cfg = gatherConfiguration(app)
            % Collects every design-relevant field into a plain struct,
            % suitable for jsonencode()/jsondecode() round-tripping.
            cfg = struct();
            cfg.TurbineType = char(app.TurbineTypeDropDown.Value);
            cfg.RPM = app.RPMEdit.Value;
            cfg.RotationDirection = char(app.RotationDropDown.Value);
            cfg.Q0 = app.Q0Edit.Value;
            cfg.Hn = app.HnEdit.Value;
            cfg.g = app.gEdit.Value;
            cfg.EtaH = app.EtaHEdit.Value;
            cfg.EtaV = app.EtaVEdit.Value;
            cfg.EtaO = app.EtaOEdit.Value;
            cfg.Sigma = app.SigmaEdit.Value;
            cfg.InterpolationScheme = char(app.InterpDropDown.Value);
            cfg.R_hub = app.RCuboEdit.Value;
            cfg.R_tip = app.RPuntaEdit.Value;
            cfg.L_z = app.LzEdit.Value;
            cfg.Re_int = app.ReIntEdit.Value;
            cfg.Re_ext = app.ReExtEdit.Value;
            cfg.gamma1_deg = app.Gamma1Edit.Value;
            cfg.gamma2_deg = app.Gamma2Edit.Value;
            cfg.HydrofoilProfile = char(app.NACADropDown.Value);
            cfg.MaxRelThickness = app.ThicknessEdit.Value;
            cfg.HubToTipRatio = app.HubToTipRatioEdit.Value;
            cfg.m_hub = app.MHubEdit.Value; cfg.p_hub = app.PHubEdit.Value;
            cfg.m_tip = app.MTipEdit.Value; cfg.p_tip = app.PTipEdit.Value;
            cfg.N_radii = app.NRadiosEdit.Value;
            cfg.N_chord = app.NCuerdaEdit.Value;
        end
        
        function saveConfiguration(app)
            [file, path] = uiputfile('*.json', 'Save Design Configuration', 'TurbineDesign_Config.json');
            if isequal(file, 0), return; end
            try
                cfg = app.gatherConfiguration();
                fid = fopen(fullfile(path, file), 'w');
                fwrite(fid, jsonencode(cfg, 'PrettyPrint', true));
                fclose(fid);
                app.StatusLabel.Text = ['Configuration saved to: ' file];
                app.StatusLabel.FontColor = [0.10 0.55 0.20];
            catch ME
                uialert(app.UIFigure, ['Could not save configuration: ' ME.message], 'Save Failed');
            end
        end
        
        function loadConfiguration(app)
            [file, path] = uigetfile('*.json', 'Load Design Configuration');
            if isequal(file, 0), return; end
            try
                raw = fileread(fullfile(path, file));
                cfg = jsondecode(raw);
                
                app.TurbineTypeDropDown.Value = cfg.TurbineType;
                app.RPMEdit.Value = cfg.RPM;
                app.RotationDropDown.Value = cfg.RotationDirection;
                app.Q0Edit.Value = cfg.Q0; app.HnEdit.Value = cfg.Hn; app.gEdit.Value = cfg.g;
                app.EtaHEdit.Value = cfg.EtaH; app.EtaVEdit.Value = cfg.EtaV; app.EtaOEdit.Value = cfg.EtaO;
                app.SigmaEdit.Value = cfg.Sigma;
                app.InterpDropDown.Value = cfg.InterpolationScheme;
                app.RCuboEdit.Value = cfg.R_hub; app.RPuntaEdit.Value = cfg.R_tip; app.LzEdit.Value = cfg.L_z;
                app.ReIntEdit.Value = cfg.Re_int; app.ReExtEdit.Value = cfg.Re_ext;
                app.Gamma1Edit.Value = cfg.gamma1_deg; app.Gamma2Edit.Value = cfg.gamma2_deg;
                app.NACADropDown.Value = cfg.HydrofoilProfile;
                app.ThicknessEdit.Value = cfg.MaxRelThickness;
                app.HubToTipRatioEdit.Value = cfg.HubToTipRatio;
                app.MHubEdit.Value = cfg.m_hub; app.PHubEdit.Value = cfg.p_hub;
                app.MTipEdit.Value = cfg.m_tip; app.PTipEdit.Value = cfg.p_tip;
                app.NRadiosEdit.Value = cfg.N_radii; app.NCuerdaEdit.Value = cfg.N_chord;
                
                % Refresh panel visibility to match the loaded values WITHOUT
                % resetting them back to factory defaults.
                isKaplan = strcmp(app.TurbineTypeDropDown.Value, 'Kaplan (Axial)');
                if isKaplan
                    app.KaplanPanel.Visible = 'on'; app.DeriazPanel.Visible = 'off';
                else
                    app.KaplanPanel.Visible = 'off'; app.DeriazPanel.Visible = 'on';
                end
                app.onProfileTypeChange();
                app.validateGeometryFields();
                
                app.StatusLabel.Text = ['Configuration loaded from: ' file ' — press COMPUTE to regenerate.'];
                app.StatusLabel.FontColor = [0.10 0.40 0.75];
            catch ME
                uialert(app.UIFigure, ['Could not load configuration: ' ME.message], 'Load Failed');
            end
        end
        
        function copyResultsToClipboard(app)
            if ~app.IsComputed || isempty(app.ResultsTable.Data)
                uialert(app.UIFigure, 'Compute geometry first.', 'Attention');
                return;
            end
            data = app.ResultsTable.Data;
            lines = strings(size(data, 1), 1);
            for i = 1:size(data, 1)
                lines(i) = sprintf('%s\t%s', string(data{i, 1}), string(data{i, 2}));
            end
            clipboard('copy', strjoin(lines, newline));
            app.StatusLabel.Text = 'Results table copied to clipboard.';
            app.StatusLabel.FontColor = [0.10 0.55 0.20];
        end
        
        function showAbout(app)
            msg = sprintf([ ...
                'KaplanDeriaz3D Airfoil Version — Professional Edition\n\n' ...
                'Solid 3D blade designer for Kaplan (axial) and Deriaz (diagonal) ' ...
                'hydraulic turbine runners, with parametric hydrofoil profiles, ' ...
                'CAD (STL/IGES) export and Excel blade-angle reports.\n\n' ...
                'The underlying hydraulic and geometric formulation (velocity ' ...
                'triangles, beta-angle interpolation laws, and NACA-based ' ...
                'hydrofoil generation) is unchanged from the original computational core.']);
            uialert(app.UIFigure, msg, 'About KaplanDeriaz3D', 'Icon', 'info');
        end
    end
end