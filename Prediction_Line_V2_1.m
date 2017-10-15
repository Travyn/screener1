


%Prediction algorithm. Inputs are as follows:

%{
V1_4 Chooses the actual closest neighbors, as opposed to sorting the
neigbors by descending index value. Also allows you to choose the number of
neighbors as an input to the program.
V1_3 Non-Dimensionalizes by the current value, rather than the first value
of the series
data = historical data for the equity, ending on current day.
prediction_window = lookahead window, in days.
lookback = desired lookback time for matching.
f = for test purposes, the future of a given equity, beginning at the end
of the array a.
neighbors = number of nearest neighbors desired.


Output:
Prediction = [m, b]; linear prediction for prediction window. 
predicted_price = predicted price at end of prediction window.
percent_increase = percent increase across prediction window. 
 

Known Constraints:

Lookback window >= 2*prediction window

%}

clear all
clear vars

tic
history = csvread('All Historical Prices.csv');



data = reshape(history,[numel(history),1]);
data2 = csvread('AJRD.csv');



neighbors = 6;
prediction_window = 10;
lookback = 45;
a = data2((end-(lookback+prediction_window-1)):(end - prediction_window));



c = [data2; data(1:end-(lookback-1))];  %c is the matrix which represents all available history for the learning matrix. The algorithm will search for a portion of c that best matches a.
%f = data2(end-(prediction_window-1):end);
a_nondim = a(:)/a(end);
z = lookback;      %a is the matrix that represents the recent history of the subject equity. The algorithm will attempt to find the closest match.     
w = size(c,1);
b = w - (lookback + prediction_window - 1);    %returns the number of rows for the ans array 

ans1 = zeros(b,1); %initializes the ans matrix with zeros. 
ans2 = zeros(z,1);  %initializes the temporary answer array, size of a.

for i = 1:b
    for j = 1:z
        k = (i+j)-1;
        %currently comparing the array a(j,:) to the array c(k,:)
        %nondimensionalize both arrays by dividing all values by the
        %current value.
        if j == 1
        q = a(end);
        r = c(k+lookback-1);

        end

        ans2(j) = (a(j)/q-c(k)/r)^2; %determines euclidian distance for each (p,v) point in the subject array and stores it in ans(2)
    end
    ans1(i) = mean(ans2);  
    
end

[B,I] = sort (ans1);

%Determine Index values of possible matches <50

possubs = I;
for i= 1:size(I,1)
    for t = (i+1):size(I,1)
        if possubs(i) == 0
        elseif ((I(i) >= (I(t)-15)) && (I(i) <= (I(t)+15)))
            possubs(t,1) = 0;  
        end
    end
end
possubs = nonzeros(possubs);
possubs = possubs(1:neighbors);
pdx = zeros(prediction_window+lookback, neighbors);

%Using index of best matches, cut portion from data beginning at the index
%of best match, and continuing through the lookback period and into the
%prediction_window (data(best_match) + lookback+ prediction_window)
for i = 1:(size(possubs,1))
    j = possubs(i);
    k = (possubs(i)+prediction_window + lookback - 1);
    pdx(:,i) = c(j:k);
    
    pdx(:,i) = pdx(:,i)/pdx(end-(prediction_window),i);
    
    
end
future = [a_nondim; (f/a(end))];



%Section plots closest relative charts for sample period, and previous x
%days taken for algorithm.
figure('Name','Historical and Prediction')
x = 1:z;
plot(x,pdx(x,:),'color','b');hold on;
plot(x,future(x,:),'color','m','linewidth',1.5);

%Section plots closest relative charts into lookahead window.
x = z:size(pdx,1);
plot(x,pdx(x,:),'Color','k');
plot(x,future(x,:),'color','g','linewidth',1.5);



%Section plots best fit line for lookahead window. Also plots actual future
%for test purposes.
x = (z+1):size(pdx,1);
out(:,1) = reshape(pdx(x,:),[],1);
out_temp = repmat(x,size(pdx,2))';
out(:,2) = out_temp(:,1);

fit = out(:,1);
fit = reshape(fit, [prediction_window, neighbors]);
fit = mean(fit,2);

prediction = polyfit(out(:,2),out(:,1),1);
y(:) = prediction(1)*(1:prediction_window) + (prediction(2) + prediction(1)*x(1));
plot(x,y,'Color','r','LineWidth',1.5);
y(:) = fit(:,1);
plot(x,y,'Color','c','LineWidth',1.5);


%Output statistics
percent_change = y(end) - 1;
predicted_price = a(end) * percent_change + a(end);
ticker_deviation = std(pdx(end,:)) * a(end);
average_end = mean(pdx(end,:)) * a(end);
actual_price = future(end) * a(end);
actual = future(end);
current_price = a(end);

%{
%Store results for accuracy testing purposes
if ticker == 0
    results = zeros(2);
    unaccounted = 0;
else
end

if predicted_price > current_price && actual_price > current_price
    results(1,1) = results(1,1) + 1;
elseif predicted_price < current_price && actual_price < current_price
    results(2,2) = results(2,2) + 1;
elseif predicted_price > current_price && actual_price < current_price
    results(2,1) = results (2,1) + 1;
elseif predicted_price < current_price && actual_price > current_price
    results(1,2) = results(1,2) + 1;
elseif predicted_price == current_price && actual_price == current_price 
    results(1,1) = results(1,1) + 1;
else
    unaccounted = unaccounted +1;
end



%}






toc


