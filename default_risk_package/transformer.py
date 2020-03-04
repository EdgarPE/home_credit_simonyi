import pandas as pd
from sklearn.base import BaseEstimator, TransformerMixin
from collections import defaultdict


class CategoryConsolidator(BaseEstimator, TransformerMixin):
    """A tranformer for combining low count observations for categorical features.

    This transformer will preserve category values that are above within top N values based on frequency,
    while bucketing together all the other values. This will fix issues
    where new data may have an unobserved category value that the training data
    did not have. Also keeps the cardinality of the category values in control to avoid a huge number of
    columns after OneHotEncoding.
    """

    def __init__(self, top_n=5, columns=None):
        """Initialize method.

        Parameters:
            columns (list): List of name of categorical columns.
            topN (int): The top N category values to keep. The rest will be replaced.
        """
        self._dict = defaultdict(list)
        self.top_n = top_n
        self.columns = columns


    def fit(self, X, y=None, **fit_params):
        """Fits transformer over X.

        Builds a dictionary of lists where the lists are category values of the
        column key for preserving, since they within the most frequent ones.
        """

        for col in self.columns:
            i = X.columns.get_loc(col) # We have to use column indexes, instead of names.
            df_ = X.iloc[:, i]
            self._dict[i] = df_.fillna('missing').value_counts()[:self.top_n].index.tolist()
        return self


    def transform(self, X, **transform_params):
        """Transforms X with new buckets.

        Args:
            X (obj): The dataset to pass to the transformer.

        Returns:
            The transformed X with grouped buckets.
        """
        X_copy = pd.DataFrame(X.copy())

        for i in self._dict:
            X_copy.iloc[:, i] = X_copy.iloc[:, i].fillna('missing').apply(
                lambda x: str(x) + '_' if x in self._dict[i] else 'other').astype('object')
        return X_copy.values.tolist()
