function shdf_plot(file_path,x,y,z)
%check for limits
load(file_path)

if shdf.nNbrOfAbsc == 1
figure()
[~,i,~] = unique({shdf.Chn.szQuantity},'first');
y.quantity={shdf.Chn.szQuantity};
y.quantity = y.quantity(sort(i));

y.unit = {shdf.Chn.szUnit};
y.unit = y.unit(sort(i));

y.logical = cellfun(@(c)strcmp(c,{shdf.Chn.szQuantity}),y.quantity,'UniformOutput',false);
for k=1:length(y.logical)
    subplot(length(y.quantity),1,k)
    plot(shdf.Absc1Data,shdf.Data(y.logical{k},:))
    xlim([x.limits(k,1) x.limits(k,2)])
    ylim([y.limits(k,1) y.limits(k,2)])
    ylabel([y.quantity{k},' in ',y.unit{k}])
    xlabel([shdf.Absc(1).szName,' in ',shdf.Absc(1).szUnit])
    legend({shdf.Chn(y.logical{k}).szName})
end
if isfield(shdf.Tags,'u_hppj_POINT_Analysis_POINT_Name')
switch  shdf.Tags.u_hppj_POINT_Analysis_POINT_Name
    case 'FFT vs. RPM'
        for k = 1:shdf.nNbrOfChn
            surf(shdf.Absc1Data,C,'EdgeColor','none')
            colormap(jet); view(0,90);
            handle_colorbar =colorbar;
            axis tight
            xlim([x.limits(k,1) x.limits(k,2)])
            ylim([y.limits(k,1) y.limits(k,2)])
            xlabel([shdf.Absc(1).szName,' in ',shdf.Absc(1).szUnit])
            ylabel([shdf.Absc(2).szName,' in ',shdf.Absc(2).szUnit])
            ylabel(handle_colorbar,[shdf.Chn(k).szQuantity,' in ',shdf.Chn(k).szUnit])
            title(shdf.Chn(k).szName)
        end
end
end

end