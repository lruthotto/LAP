%
%   This script sets up and runs the coupled super-resolution problem using
%   various objective functions
%

%%
%%%%%%%%%%%%%%%%%%%%%
% Setup the problem %
%%%%%%%%%%%%%%%%%%%%%

setup2DSuperResProb;

% Set up params for all solvers

%%
%%%%%%%%%%%%
% Run full %
%%%%%%%%%%%%
FULL = @(y) CoupledSRObjFctn(y, d, omega, mf, mc, 'alpha', alpha, 'matrixFree',0);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = [1*ones(size(x0(:))); Inf*ones(prod(size(w0(:,2:end))),1)];
lower_bound = [0*ones(size(x0(:))); -Inf*ones(prod(size(w0(:,2:end))),1)];
solver = 'mbFULLlsdir';

tic();
[y_FULL, his_FULL] = GaussNewtonProj(FULL,[x0(:); reshape(w0(:,2:end),[],1)],'upper_bound', upper_bound, 'lower_bound', lower_bound,'solver', solver, 'solverTol',1e-2, 'maxIter', maxIter,'iterSave',true);
time_FULL = toc();

x_FULL = y_FULL(1:prod(mf));
w_FULL = [zeros(3,1), reshape(y_FULL(prod(mf)+1:end),3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run LAP with direct regularization %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LAPd = @(y) CoupledSRObjFctn(y, d, omega, mf, mc, 'alpha', alpha, 'matrixFree',1);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = [1*ones(size(x0(:))); Inf*ones(prod(size(w0(:,2:end))),1)];
lower_bound = [0*ones(size(x0(:))); -Inf*ones(prod(size(w0(:,2:end))),1)];
solver = 'mfLAPlsdir';

tic();
[y_LAPd, his_LAPd] = GaussNewtonProj(LAPd,[x0(:); reshape(w0(:,2:end),[],1)],'upper_bound', upper_bound, 'lower_bound', lower_bound,'solver', solver, 'solverTol',1e-2, 'maxIter', maxIter,'iterSave',true);
time_LAPd = toc();

x_LAPd = y_LAPd(1:prod(mf));
w_LAPd = [zeros(3,1), reshape(y_LAPd(prod(mf)+1:end),3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run LAP with hybrid regularization %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LAPh = @(y) CoupledSRObjFctn(y, d, omega, mf, mc, 'alpha', 0, 'regularizer', 'hybr', 'matrixFree',1);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = [1*ones(size(x0(:))); Inf*ones(prod(size(w0(:,2:end))),1)];
lower_bound = [0*ones(size(x0(:))); -Inf*ones(prod(size(w0(:,2:end))),1)];
solver = 'mfLAPlsHyBR';

tic();
[y_LAPh, his_LAPh] = GaussNewtonProj(LAPh,[x0(:); reshape(w0(:,2:end),[],1)],'upper_bound', upper_bound, 'lower_bound', lower_bound,'solver', solver, 'solverTol',1e-2, 'maxIter', maxIter,'iterSave',true);
time_LAPh = toc();

x_LAPh = y_LAPh(1:prod(mf));
w_LAPh = [zeros(3,1), reshape(y_LAPh(prod(mf)+1:end),3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run VarPro with discrete gradient regularizer %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VPd = @(w) VarproSRObjFctn(w, d, omega, mf, mc, 'alpha', 0.01, 'matrixFree', 0);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = Inf*ones(prod(size(w0(:,2:end))),1);
lower_bound = -Inf*ones(prod(size(w0(:,2:end))),1);

tic();
[w_VPd, his_VPd] = GaussNewtonProj(VPd, reshape(w0(:,2:end),[],1),'upper_bound', upper_bound, 'lower_bound', lower_bound,'solver', [], 'maxIter', maxIter, 'iterSave', true);
time_VPd = toc();

% Extract x with a function call
[~,para] = VPd(w_VPd);
x_VPd = para.Tc;
w_VPd = [zeros(3,1), reshape(w_VPd,3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run VarPro with discrete identity regularizer %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VPe = @(w) VarproSRObjFctn(w, d, omega, mf, mc, 'alpha', 0.01, 'regularizer', 'eye', 'matrixFree', 1);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = Inf*ones(prod(size(w0(:,2:end))),1);
lower_bound = -Inf*ones(prod(size(w0(:,2:end))),1);

tic();
[w_VPe, his_VPe] = GaussNewtonProj(VPe, reshape(w0(:,2:end),[],1),'upper_bound', upper_bound, 'lower_bound', lower_bound, 'solver', [], 'maxIter', maxIter, 'iterSave', true);
time_VPe = toc();

% Extract x with a function call
[~,para] = VPe(w_VPe);
x_VPe = para.Tc;
w_VPe = [zeros(3,1), reshape(w_VPe,3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run block coordinate descent with discrete gradient regularizer %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BCDd = @(y, flag) DecoupledSRObjFctn(y, d, omega, mf, mc, flag, 'alpha', 0.01, 'regularizer', 'grad', 'matrixFree', 1);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = [1*ones(size(x0(:))); Inf*ones(prod(size(w0(:,2:end))),1)];
lower_bound = [0*ones(size(x0(:))); -Inf*ones(prod(size(w0(:,2:end))),1)];
solver = cell(2,1); solver{1} = 'mfBCDlsdir'; solver{2} = 'mbBCDchol';
solverTol = [1e-2; 1e-2];
blocks = [1 , length(x0(:))+1; length(x0(:)), length(x0(:))+numel(w0(:,2:end))];

tic();
[y_BCDd, his_BCDd] = CoordDescent(BCDd, [x0(:); reshape(w0(:,2:end),[],1)], blocks, 'upper_bound', upper_bound, 'lower_bound', lower_bound, 'solver', solver, 'solverTol', solverTol, 'maxIter', maxIter, 'iterSave', true);
time_BCDd = toc();

x_BCDd = y_BCDd(1:prod(mf));
w_BCDd = [zeros(3,1), reshape(y_BCDd(prod(mf)+1:end),3,[])];

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run block coordinate descent with hybrid regularizer %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BCDh = @(y, flag) DecoupledSRObjFctn(y, d, omega, mf, mc, flag, 'regularizer', 'hybr', 'matrixFree', 1);

% Set some method parameters
maxIter = 20;
iterSave    = true;
upper_bound = [1*ones(size(x0(:))); Inf*ones(prod(size(w0(:,2:end))),1)];
lower_bound = [0*ones(size(x0(:))); -Inf*ones(prod(size(w0(:,2:end))),1)];
solver = cell(2,1); solver{1} = 'mfBCDlshybr'; solver{2} = 'mbBCDchol';
solverTol = [1e-2; 1]; 
blocks = [1 , length(x0(:))+1; length(x0(:)), length(x0(:))+numel(w0(:,2:end))];

tic();
[y_BCDh, his_BCDh] = CoordDescent(BCDh, [x0(:); reshape(w0(:,2:end),[],1)], blocks, 'upper_bound', upper_bound, 'lower_bound', lower_bound, 'solver', solver, 'solverTol', solverTol, 'maxIter', maxIter, 'iterSave', true);
time_BCDh = toc();

x_BCDh = y_BCDh(1:prod(mf));
w_BCDh = [zeros(3,1), reshape(y_BCDh(prod(mf)+1:end),3,[])];

%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Relative Errors and Timings %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('norm(x0 - xtrue)/norm(x_true) = %1.4e \n', norm(x0(:) - xtrue(:))/norm(xtrue(:)));
fprintf('norm(w0 - wtrue)/norm(w_true) = %1.4e \n', norm(w0(:) - wtrue(:))/norm(wtrue(:)));

fprintf('norm(x_FULL - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_FULL(:) - xtrue(:))/norm(xtrue(:)), time_FULL);
fprintf('norm(w_FULL - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_FULL(:) - wtrue(:))/norm(wtrue(:)), time_FULL);

fprintf('norm(x_LAPd - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_LAPd(:) - xtrue(:))/norm(xtrue(:)), time_LAPd);
fprintf('norm(w_LAPd - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_LAPd(:) - wtrue(:))/norm(wtrue(:)), time_LAPd);

fprintf('norm(x_LAPh - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_LAPh(:) - xtrue(:))/norm(xtrue(:)), time_LAPh);
fprintf('norm(w_LAPh - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_LAPh(:) - wtrue(:))/norm(wtrue(:)), time_LAPh);

fprintf('norm(x_VPd - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_VPd(:) - xtrue(:))/norm(xtrue(:)), time_VPd);
fprintf('norm(w_VPd - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_VPd(:) - wtrue(:))/norm(wtrue(:)), time_VPd);

fprintf('norm(x_VPe - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_VPe(:) - xtrue(:))/norm(xtrue(:)), time_VPe);
fprintf('norm(w_VPe - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_VPe(:) - wtrue(:))/norm(wtrue(:)), time_VPe);

fprintf('norm(x_BCDd - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_BCDd(:) - xtrue(:))/norm(xtrue(:)), time_BCDd);
fprintf('norm(w_BCDd - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_BCDd(:) - wtrue(:))/norm(wtrue(:)), time_BCDd);

fprintf('norm(x_BCDh - xtrue)/norm(x_true) = %1.4e in %1.2secs \n', norm(x_BCDh(:) - xtrue(:))/norm(xtrue(:)), time_BCDh);
fprintf('norm(w_BCDh - wtrue)/norm(w_true) = %1.4e in %1.2secs \n', norm(w_BCDh(:) - wtrue(:))/norm(wtrue(:)), time_BCDh);