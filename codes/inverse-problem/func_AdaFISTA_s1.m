function [x, its, ek, phik, r, Rk, Vk] = func_AdaFISTA_s1(para, GradF,ProxJ, ObjPhi, J, p,q,r)
% The Adaptive FISTA
itsprint(sprintf('        step %08d: norm(ek) = %.3e', 1,1), 1);
w = 10;
if strcmp(J, 'infty'); w = 1e3; end

% set up
beta = para.beta;
mu = para.mu;
n = para.n;
% f = para.f;

A = para.A;
% alpha = 0; %strong convexity

gamma = 1 *beta;
tau = mu*gamma;

if strcmp(J, 'mc')
    FBS = @(y, gamma, tau) ProxJ(y-gamma*GradF(y), tau, n);
else
    FBS = @(y, gamma, tau) ProxJ(y-gamma*GradF(y), tau);
end
%% FBS iteration
x0 = zeros(prod(n), 1);

x = x0;
y = x0;

tol = 1e-10;
maxits = 1e5;

ek = zeros(maxits, 1);
phik = zeros(maxits, 1);
Vk = zeros(maxits, 1);

Rk = zeros(maxits, 1);
cR = 1;

first = 1;

t = 1;

its = 1;
while(its<maxits)
    
    x_old = x;
    y_old = y;
    
    x = FBS(y, gamma, tau);
    
    t_old = t;
    t = (p + sqrt(q+r*t_old^2)) /2;
    a = (t_old-1) /t;
    y = x + a*(x-x_old);
    
    
    %%% update r_k
    vk = (y_old(:)-x(:))'*(x(:)-x_old(:));
    Vk(its) = vk;
%     if vk >= 0% mod(its,w2)==0
%         Rk(cR) = r; cR = cR + 1;
%         r = alpha_est(p,gamma, x, A, J);
%         
%         % t = 1;
%         if t >= 4*p/(4 - r); t = 4*p/(4 - r)/1.1; end
%     end
    
    if first % fist oscillation
        
        if vk >= 0
            r = alpha_est(p,gamma, x, A, J);
            t = 4*p/(4 - r)/1.1;
            
            kpos = its+10;
            gap = its;
            
            first = 0;
            second = 1;
            
            Rk(cR) = r; cR = cR + 1;
        end
        
    elseif second
        
        if (vk <= 0)&&(its-kpos>=2*gap)
            
            sum_k = sum( diff( sign( Vk(kpos+1:its) ) ) );
            
            if sum_k==0
                r = alpha_est(p,gamma, x, A, J);
                % t = 1;
                Rk(cR) = r; cR = cR + 1;
                
                second = 0;
            end
            
        end
        
    end
    
    %%%%%%% stop?
    normE = norm(x_old-x, 'fro');
    
    if mod(its,w)==0; itsprint(sprintf('        step %08d: norm(ek) = %.3e', its,normE), its); end
    
    ek(its) = normE;
    phik(its) = ObjPhi(x);
    if (normE<tol)||(normE>1e10); break; end
    
    its = its + 1;
    
end
fprintf('\n');

ek = ek(1:its-1);
phik = phik(1:its-1);
Vk = Vk(1:its-1);

Rk = Rk(1:cR-1);

% EoF