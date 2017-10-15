


%Prediction algorithm. Inputs are as follows:

%{

V1_3 Non-Dimensionalizes by the current value, rather than the first value
of the series
data = historical data for the equity, ending on current day.
prediction_window = lookahead window, in days.
lookback = desired lookback time for matching.
f = for test purposes, the future of a given equity, beginning at the end
of the array a.



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

prediction_window = 15;
lookback = 90;
f = csvread('future.csv');
f = f(1:prediction_window);
data = csvread('Data.csv');
a = data((end-(lookback-1)):end);
a_nondim = a(:)/a(end);
z = size(a);      %a is the matrix that represents the recent history of the subject equity. The algorithm will attempt to find the closest match.     
c = data(1:end-(lookback-prediction_window));  %c is the matrix which represents all available history for the learning matrix. The algorithm will search for a portion of c that best matches a.
w = size(c);
b = w - (z - 1);    %returns the number of rows for the ans array 

ans1 = zeros(b); %initializes the ans matrix with zeros. 
ans2 = zeros(z);  %initializes the temporary answer array, size of a.

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

        ans2(j) = sqrt((a(j)/q-c(k)/r)^2); %determines euclidian distance for each (p,v) point in the subject array and stores it in ans(2)
    end
    ans1(i) = mean(ans2);    
end

[B,I] = sort (ans1);

%{

I = I(1:100);
I = sort(I,'descend');


%Determine Index values of possible matches <50

possubs = zeros(50,1);
possubs(1) = I(1);
for i = 2:50
    if I(i) <= (I(i-1)-15)
      possubs(i) = I(i);
    end
    possubs = nonzeros(possubs);
end




pdx = zeros((prediction_window+size(a,1)),(size(possubs,1)));

for i = 1:(size(possubs,1))
    j = possubs(i);
    k = (possubs(i)+size(pdx,1) - 1);
    pdx(:,i) = c(j:k);
    
    pdx(:,i) = pdx(:,i)/pdx(end-(prediction_window),i);
    
    
end

future = [a_nondim; f/a(end)];
%future(:) = future(:)/future(1);

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
out_temp = repmat(x:size(pdx,1),size(pdx,2))';
out(:,2) = out_temp(:,1);
prediction = polyfit(out(:,2),out(:,1),1);
y(:) = prediction(1)*(1:prediction_window) + a_nondim(end);
plot(x,y,'Color','r','LineWidth',1.5);
percent_change = prediction(1) * prediction_window;
predicted_price = a(end) * percent_change + a(end);



%}



toc


