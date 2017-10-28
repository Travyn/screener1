
% File input is of format {col1, col2, col3, ...}
% Why not use a least-squares regression? Either A\b or fit (https://www.mathworks.com/help/curvefit/least-squares-fitting.html)


clear all

tic
a = csvread('predict.csv');
z = size(a,1);      %a is the matrix that represents the recent history of the subject equity. The algorithm will attempt to find the closest match.     
c = csvread('history.csv');  %c is the matrix which represents all available history for the learning matrix. The algorithm will search for a portion of c that best matches a.
y = size(c,1);
%c(395:399,:) = 1.0;
b = y - (z - 1);    %returns the number of rows for the ans array 

ans1 = zeros(b,1); %initializes the ans matrix with zeros. 
ans2 = zeros(1,z);  %initializes the temporary answer array, size of a.

for i = 1:b
    for j = 1:z
        k = (i+j)-1;
        %currently comparing the array a(j,:) to the array c(k,:)
        %nondimensionalize both arrays by dividing all values by the first
        %value.
        if j == 1
        q = a(j,:);
        r = c(k,:);
        end
        
        % Is this just your residual?
        ans2(j) = sqrt((a(j,1)/q(1)-c(k,1)/r(1))^2 + (a(j,2)/q(2)-c(k,2)/r(2))^2); %determines euclidian distance for each (p,v) point in the subject array and stores it in ans(2)
    end
    ans1(i,1) = mean(ans2);    
end

[B,I] = sort (ans1,1);

toc





