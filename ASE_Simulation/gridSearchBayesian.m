function gridSearchBayesian
    % Perform Bayesian inference on ASE qBOLD data from qASE.m using a 2D grid
    % search. Requires qASE_model.m, which should all be in the same folder.
    % Also requires a .mat file of simulated ASE qBOLD data produced by qASE.m
    %
    % 
    %       Copyright (C) University of Oxford, 2016-2018
    %
    % 
    % Created by MT Cherukara, 17 May 2016
    %
    % CHANGELOG:
    %
    % 2018-08-23 (MTC). Various changes.


%% Load the Data
load('data_qASE_example.mat'); % this is generated by qASE.m

% Choose parameters, their range, and the number of points each way:
pnames = { 'R2p'    ; 'zeta'     };
interv = [ 3.5, 7.5 ; 0.01, 0.07 ];
np     = [ 100     ; 100       ];

% Specifically for testing critical tau.
params.tc_man = 0;
params.tc_val = 0.024;

% extract relevant parameters
sigma = mean(params.sig);   % real std of noise
ns = length(S_sample); % number of data points
params.R2p = params.dw.*params.zeta;

% fill in TE if necessary
if ~exist('TE_sample','var')
    TE_sample = params.TE;
end

% are we inferring on R2'?
if any(strcmp(pnames,'R2p'))
    noDW = 1; % this changes what happens in MTC_qASE_model.m
else
    noDW = 0;
end

%% Bayesian Inference on two parameters, using grid search
    
% pull out parameter names
pn1 = pnames{1};
pn2 = pnames{2};

% find true values of parameters
trv(1) = eval(['params.',pn1]); % true value of parameter 1
trv(2) = eval(['params.',pn2]); % true value of parameter 2

% generate parameter distributions
pv1 = linspace(interv(1,1),interv(1,2),np(1));
pv2 = linspace(interv(2,1),interv(2,2),np(2));

pos = zeros(np(1),np(2));

for i1 = 1:np(1)
    % loop through parameter 1
    
    % create a parameters object
    looppars = updateParams(pv1(i1),params,pn1);
    posvec = zeros(1,np(2));
    
    pv22 = pv2; % to avoid using pv2 as a broadcast variable
    
    for i2 = 1:np(2)
        % loop through parameter 2
        
        % create a parameters object
        inpars = updateParams(pv22(i2),looppars,pn2);
        
        % run the model to evaluate the signal with current params
        S_mod = qASE_model(T_sample,TE_sample,inpars,noDW);
        
        % normalize
        S_mod = S_mod./max(S_mod);
        
        % calculate posterior based on known noise value
        posvec(i2) = calcLogLikelihood(S_sample,S_mod,sigma);
        
    end % for i2 = 1:np2
    
    pos(i1,:) = posvec;
    
end % for i1 = 1:np1

    
%% Display Results

% create  figure
figure; hold on; box on;

% Plot 2D grid search results
surf(pv2,pv1,exp(pos));
view(2); shading flat;
c=colorbar;

% plot true values
plot3([trv(2),trv(2)],[  0, 1000],[1e40,1e40],'k-');
plot3([  0, 1000],[trv(1),trv(1)],[1e40,1e40],'k-');

% outline
plot3([pv1(  1),pv2(  1)],[pv1(  1),pv1(end)],[1,1],'k-','LineWidth',0.75);
plot3([pv2(end),pv2(end)],[pv1(  1),pv1(end)],[1,1],'k-','LineWidth',0.75);
plot3([pv2(  1),pv2(end)],[pv1(  1),pv1(  1)],[1,1],'k-','LineWidth',0.75);
plot3([pv2(  1),pv2(end)],[pv1(end),pv1(end)],[1,1],'k-','LineWidth',0.75);

% Labels
xlabel(pn2);
ylabel(pn1);
ylabel(c,'Posterior Probability Density');
axis([min(pv2),max(pv2),min(pv1),max(pv1)]);
set(gca,'YDir','normal');

end

%% UpdateParams function
function PARAMS = updateParams(VALUES,PARAMS,INFER)
    % Update the PARAMS structure

    if strcmp(INFER,'OEF')
        PARAMS.OEF = VALUES;
    elseif strcmp(INFER,'zeta')
        PARAMS.zeta = VALUES;
    elseif strcmp(INFER,'R2p')
        PARAMS.R2p = VALUES;
    elseif strcmp(INFER,'lam0')
        PARAMS.lam0 = VALUES;
    elseif strcmp(INFER,'R2e')
        PARAMS.R2e = VALUES;
    elseif strcmp(INFER,'dF')
        PARAMS.dF = VALUES;
    elseif strcmp(INFER,'R2t')
        PARAMS.R2t = VALUES;
    elseif strcmp(INFER,'geom')
        PARAMS.geom = VALUES;
    else
        disp('----updateParams: Invalid parameter specified');
    end
    
end
    
%% calcLogLikelihood function
function L = calcLogLikelihood(data,model,sigma)
    % Calculate log likelihood

    % compute maximum possible loglikelihood
    M = -0.5.*length(data).*log(2.*pi.*sigma.^2);

    % compute sum of square difference
    S = (1./(2.*sigma.^2)).*sum((data-model).^2);

    % add up loglikelihood
    L = M - S;

end