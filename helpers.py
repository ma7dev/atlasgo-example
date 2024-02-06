from clickhouse_driver import Client as CHClient
from IPython.display import display

class Client():
    def __init__(
        self,
        host,
        port,
        user,
        password,
        notebook=True
    ):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.notebook = notebook

        self._client = CHClient(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            # settings={'use_numpy': True}
        )

    def execute(self, input):
        return self._client.execute(input)
    def query_dataframe(self, input):
        return self._client.query_dataframe(input)

    def run(self, queries, verbose=True, pandas=True, skip=False,just_output=False,title=None):
        if skip: return
        if title is not None and title != "":
            print(f"<< {title} >>")
        queries = [query.strip() for query in queries.split(';') if query.strip() != '']
        if verbose and not just_output: print(f"Running {len(queries)} commands")
        for i, query in enumerate(queries):
            if verbose and not just_output:
                print(f"Running: (order={i})")
                print(query)
            if pandas:
                output = self._client.query_dataframe(query)
                if verbose:
                    if not output.empty:
                        print("Output:")
                        if self.notebook:
                            display(output)
                        else:
                            print(output)
            else:
                output = self._client.execute(query)
                if verbose:
                    if output:
                        print("Output:")
                        print(output)