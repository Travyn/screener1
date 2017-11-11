#!/usr/bin/env python3

# Mark Agate

import pandas as pd
import datetime
import time
import matplotlib.pyplot as plt
import numpy as np
import scipy.optimize as spo


# Script attempts to find the optimum portfolio allocations for given symbols.
# Initial investment can be anything as it should be normalized. A good data
# process would be to plot each iteration of the optimizer to make sure it is
# running appropriately.
#
# User defined variables: initial_investment (dollars), symbols, stat(date),
# end(date), allocs (initial allocation)
#
# Outputs: Optimum allocations as allocsNew and allocsNewRound (rounded but also
# stored if this were to be done with machine learning or high frequency trading.)

#----- User variables -----#
initial_investment = 1000
symbols = ['FORD','TSLA', 'AAPL']
start = datetime.datetime(2015, 1, 1)
end = datetime.datetime(2017, 10, 25)
allocs = [0.2,0.3, 0.3]

#----- Code -----#

# initialize dates and load files, making sure SPY was traded on that day and
# eliminate nans

dates = pd.date_range(start, end)
df_dates = pd.DataFrame(index=dates)

spy = pd.read_csv("SPY.csv", index_col="Date", parse_dates=True)
spy = spy.rename(columns={'Adj Close':'SPY'})

df_adjClose = df_dates.join(spy["SPY"], how='inner')
df_adjClose = df_adjClose.dropna()

# Read in other stock data and join with SPY to make sure that the market was open
for symbol in symbols:
    df_temp = pd.read_csv("%s.csv" %symbol, index_col="Date", parse_dates=True)
    df_temp = df_temp.rename(columns={"Adj Close":symbol})
    df_adjClose = df_adjClose.join(df_temp[symbol])

# Remove spy column and normalize
del df_adjClose['SPY']
df_adjClose_normalized = df_adjClose/df_adjClose.iloc[0,:]

# Daily returns for portfolio value
def compute_daily(df):
    '''
    daily_returns = df.copy() # copy of the data frame to match size and column names
    daily_returns[1:] = (df[1:]/df[:-1].values) - 1 # daily returns for row 1 onwards
    daily_returns.ix[0, :] = 0 # set daily returns for row zero to zero
    '''
    # with pandas
    daily_returns=(df/df.shift(1))-1
    if df.ndim > 1:
        daily_returns.iloc[0,:]=0 # Replace the nans
    else:
        daily_returns.iloc[0]=0

    return daily_returns

# The function to be minimized
def sharpeFun(allocs, initial_investment, df_adjClose_normalized):
    # calculate portfoli value based on allocations
    alloced = df_adjClose_normalized*allocs
    pos_vals = alloced*initial_investment
    port_val = pos_vals.sum(axis=1)

    # calculate portfolio daily returns of portfolio
    port_val_daily_returns = compute_daily(port_val)

    # calculate sharpe ratio
    avg_daily_return = port_val_daily_returns.mean()
    std_daily_return = port_val_daily_returns.std()
    daily_rf = (1.0+0.1)**(1./252) - 1

    # sharpe ratio annualized and multiplied by -1 for minimzer to work
    S = -(((avg_daily_return-daily_rf)/std_daily_return)**(1./252))
    return S

# call to the optimizer and set parameters
def optimizeSharpe(allocs, initial_investment, df_adjClose_normalized):
    # Constrain to have allocations sum to 1 and be positive
    cons = ({'type': 'eq',
            'fun': lambda allocs: np.sum(allocs) - 1})
    bnds = [(0, None,) for i in range(len(allocs))]

    # call minimizer using Sequential Least SQuares Programming
    optimalAllocs = spo.minimize(sharpeFun, allocs, args=(initial_investment,df_adjClose_normalized,),bounds=bnds, constraints=cons, method='SLSQP', options={'disp':True})

    return optimalAllocs


# call optimizer and show output as rounded
allocsNew = optimizeSharpe(allocs, initial_investment, df_adjClose_normalized)

allocsNewRound = np.round(allocsNew.x,2)
print('Optimum allocations: {}'.format(allocsNewRound))
print(symbols)
