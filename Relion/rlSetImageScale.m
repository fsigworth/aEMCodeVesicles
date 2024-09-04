function [mi,m,origImageSize]=rlSetImageScale(mi,mode,nFrames);
% Set the size and scale parameters in the mi struct. If nargout>1 we load and
% scale the image m and set the scale parameters.
% mi.padImageSize is always set to the "nice" padded image size. If you are
% going to use the original micrograph as the working image, you should 
% use mi.imageSize.
% There are three modes for scaling the contrast.
% 0. Assume the micrograph is already scaled to fractional contrast.
%   mi.imageNormScale set to 1.
% 1. Read the micrograph, pad the image to a nice size, convert to fractional contrast
%   (this is our traditional method.) Set mi.imageSize and mi.imageMedian.
%   Scale up both the median and the image by sqrt(nFrames), which should 
%   be >1 to fix MotionCor2's wrong dc scaling.
%   *** Set nFrames=1 for other motion correction programs.***
%   If we need to get the fractional contrast micrograph from the original
%   micrograph m0, do this:
%   To get the fractional contrast image from the raw micrograph,
%    mFrac=mi.imageNormScale*(m0-mi.imageMedian);

% 2. Read the micrograph, insert its actual size as mi.imageSize, and
%   compute mi.imageNormScale and mi.imageMedian by looking at the noise
%   spectrum. Assume that we'll use the original micrograph as the
%     "processed" or "merged" image. Compute the normalization we'll have to
%     apply to make the AC image component approximately equal to fractional
%     contrast. We'll estimate the variance by averaging the 1D power spectrum
%     from 0.3 to 0.7 * Nyquist. Assuming an arbitrary image scaling by a, the
%     est variance of a counting image should be a^2 * pixelDose, which will be
%     (a * size of original pixel)^2 * doses(1), with a being the unknown
%     scaling factor. (By the scaling used by MotionCor2, the "size of original
%     pixel" should be a superres pixel. The final fractional-contrast image
%     will have the variance 1/pixelDose. We'll have to get it by scaling the
%     raw image m0 by 1/sqrt(est variance*pixelDose). In the end we'll get the
%     scaled micrograph, after computing the median, by
%     scaledImg = ( m0-median(m0(:)) )*mi.imageNormScale;
% 3. Simple, approx compatibility with any micrograph: set mi.imageNormScale such
%     that the std of the final scaled image will be 0.1.     

minMedian=25; % This would be high for MotionCor2 data but low (=dose*cpe)
% for correctly-scaled data. median<minMedian should give a warning.

    m0=0; % default returned value.
    mc=0;
    m=0;
micName=[mi.imagePath mi.imageFilenames{1}];
micFound=exist(micName,'file');
if nargout>1 % we are returning an image
    if micFound
        m0=RemoveOutliers(ReadMRC(micName));
        me=mean(m0(:));
        med=median(m0(:));
    else
        disp(['Micrograph file not found: ' micName]);
        me=0;
        med=0;
    end;
    origImageSize=size(m0);
    if numel(origImageSize)<2
        origImageSize(2)=origImageSize(1);
    end;
    mi.imageSize=origImageSize;
    niceImageSize=NextNiceNumber(origImageSize,5,8);
    mi.padImageSize=niceImageSize;
    mc=Crop(m0-me,niceImageSize); % mc is padded and mean-subtr. raw image
    % DONT remove outliers
end;

% defaults for motion corr bug-correction
mi.imageACScale=1;
mi.imageDCScale=1;

switch mode
    case 0 % image is already normalized (K3 data?)
        mi.imageNormScale=1;
        mi.imageMedian=med;
        m=mc-med;            
    case 1 % We assume we know the DC component correctly, or else use the
        % correction for MotionCor2's error to scale up [should it be down?]
        % the DC value.
            if mi.camera==7 % k3 camera
                % Assuming superres raw data, motionCor2 yields raw cpe/4.
                % So with 10% coincidence loss, cpe=0.9/4.
                % We scale relative to theoretical number of counts/pixel:
                mi.imageNormScale=1/(mi.doses*mi.pixA^2*mi.cpe);
                mi.imageACScale=8; % strange behavior of MotionCor2
                mi.imageDCScale=1;
                % How to use the parameters to get a norm. image range (0..1)
                m1=(mc*mi.imageACScale+me*mi.imageDCScale)*mi.imageNormScale;
                mi.imageMedian=med;
                % subtract the median
                m=m1-med;
            else
                disp('Only k3 camera supported at present')
            end;
%             if mi.imageMedian<minMedian
%                 disp(['   Image median is low? ' num2str(mi.imageMedian)]);
%             end;
        % To reconstruct the original micrograph scaling (in cpe) do this:
        % m=(m0*mi.imageNormScale)+mi.imageMedian; % The product of the
        %   two factors should be 1 if we aren't doing the motioncor2
        %   correction.
        % To get the fractional contrast image from the raw micrograph,
        % mFrac=mi.imageNormScale*(m0-mi.imageMedian);
        
    case 2 % don't know scaling or the DC value, estimate from the image.
%       Estimate shot noise from the mean power spectrum 0.3 ... 0.7 x Nyquist
        sds=floor(min(mi.imageSize)/256); % Downsampling factor for spectrum
        mCtr=single(Crop(m0,256*sds)); % Grab a square region of the image.
        sp1=RadialPowerSpectrum(mCtr,0,sds);
        spN=numel(sp1);
        spLims=round(spN*[.3 .7]);
        estVar=sum(sp1(spLims(1):spLims(2)))/diff(spLims);
        mi.imageNormScale=1/(mi.pixA*sqrt(mi.doses(1)*estVar));
%         Multiply the image by this to get a normalized image.
        mi.imageMedian=med; % best estimate we have of the main image mean.
        m=mc*mi.imageNormScale;

    case 3 % Simple, rough scaling assuming ~white noise, do this only for the first image.
        sigma=std(m0(:));
        if nargout>1 && sigma>0 % we have an image; update the scaling values
            mi.imageNormScale=0.2/sigma;
            mi.imageMedian=med;
            m=mc*mi.imageNormScale;
        else
            error('Mode 3 but no image available');
        end;
    otherwise
        error('Mode not recognized');
end;
