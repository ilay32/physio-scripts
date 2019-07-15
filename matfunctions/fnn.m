function [FNN,embd] = fnn(x,tao,mmax,rtol,atol,plt)
    %x : time series
    %tao : time delay
    %mmax : maximum embedding dimension
    %reference:M. B. Kennel, R. Brown, and H. D. I. Abarbanel, Determining
    %embedding dimension for phase-space reconstruction using a geometrical 
    %construction, Phys. Rev. A 45, 3403 (1992). 
    %author:"Merve Kizilkaya"
    %rtol=15
    %atol=2;
    N=length(x);
    Ra=std(x,1);
    if nargin == 5
        plt = false;
    end
    for m=1:mmax
        M=N-m*tao;
        %Y=psr_deneme(x,m,tao,M);
        Y = lagmatrix(x,tao*(0:m));
        Y = Y(1:M,:);
        FNN(m,1)=0;
        for n=1:M
            y0=ones(M,1)*Y(n,:);
            distance=sqrt(sum((Y-y0).^2,2));
            [neardis nearpos]=sort(distance);

            D=abs(x(n+m*tao)-x(nearpos(2)+m*tao));
            R=sqrt(D.^2+neardis(2).^2);
            if D/neardis(2) > rtol || R/Ra > atol
                 FNN(m,1)=FNN(m,1)+1;
            end
        end
    end
    FNN=(FNN./FNN(1,1))*100;
    if plt
        figure
        plot(1:length(FNN),FNN)
        grid on;
        title('Minimum embedding dimension with false nearest neighbours')
        xlabel('Embedding dimension')
        ylabel('The percentage of false nearest neighbours')
    end
    [~,embd] = min(FNN);
end

