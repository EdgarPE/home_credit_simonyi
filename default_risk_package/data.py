import pandas as pd


def subsample(df, target_col):
    """
    Under-sample date for balanced binary classification classes.

    :param df: pandas.DataFrame to rebalance
    :param target_col: pandas.Series with target values
    :return: pandas.Dataframe with balanced classes
    """
    class_0 = df[target_col == 0]
    class_1 = df[target_col == 1]

    class_0_sub = class_0.sample(class_1.shape[0])

    return pd.concat([class_0_sub, class_1], axis=0).sort_index().reset_index(drop=True)
