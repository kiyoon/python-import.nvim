M = {}

-- If nothing is found, it will return `import ..` anyway.
-- However, it might take some time to search the candidate,
-- so we define a list of common imports here.
M.default_import = {
  "pickle",
  "os",
  "sys",
  "re",
  "json",
  "time",
  "datetime",
  "random",
  "math",
  "importlib",
  "argparse",
  "shutil",
  "copy",
  "dataclasses",
  "enum",
  "functools",
  "glob",
  "itertools",
  "pathlib",
  "abc",
  "contextlib",
  "collections",
  "io",
  "multiprocessing",
  "typing",
  "typing_extensions",
  "setuptools",

  -- third-party
  "PIL",
  "easydict",
  "rich",
  "selenium",
  "neptune",
  "torch",
}

M.default_import_as = {
  mp = "multiprocessing",
  np = "numpy",
  npt = "numpy.typing",
  pd = "pandas",
  pl = "polars",
  plt = "matplotlib.pyplot",
  o3d = "open3d",
  F = "torch.nn.functional",
  tf = "tensorflow",
  nx = "networkx",
  rx = "rustworkx",
}

M.default_import_from = {
  ABC = "abc",
  ABCMeta = "abc",
  abstractclassmethod = "abc",
  abstractmethod = "abc",
  abstractproperty = "abc",
  abstractstaticmethod = "abc",

  ArgumentParser = "argparse",
  ArgumentError = "argparse",
  ArgumentTypeError = "argparse",
  HelpFormatter = "argparse",
  ArgumentDefaultsHelpFormatter = "argparse",
  RawDescriptionHelpFormatter = "argparse",
  RawTextHelpFormatter = "argparse",
  MetavarTypeHelpFormatter = "argparse",
  Namespace = "argparse",

  copy2 = "shutil",
  contextmanager = "contextlib",
  nullcontext = "contextlib",
  closing = "contextlib",
  deepcopy = "copy",

  OrderedDict = "collections",
  namedtuple = "collections",
  defaultdict = "collections",

  Iterable = "collections.abc",
  Sequence = "collections.abc",

  date = "datetime",
  -- datetime = "datetime",
  timezone = "datetime",

  dataclass = "dataclasses",
  field = "dataclasses",
  fields = "dataclasses",
  asdict = "dataclasses",
  astuple = "dataclasses",
  is_dataclass = "dataclasses",
  make_dataclass = "dataclasses",
  Enum = "enum",
  EnumMeta = "enum",
  Flag = "enum",
  IntEnum = "enum",
  IntFlag = "enum",

  update_wrapper = "functools",
  wraps = "functools",
  WRAPPER_ASSIGNMENTS = "functools",
  WRAPPER_UPDATES = "functools",
  total_ordering = "functools",
  cache = "functools",
  cmp_to_key = "functools",
  lru_cache = "functools",
  reduce = "functools",
  partial = "functools",
  partialmethod = "functools",
  singledispatch = "functools",
  singledispatchmethod = "functools",
  cached_property = "functools",

  glob = "glob",
  iglob = "glob",

  Pool = "multiprocessing",
  Process = "multiprocessing",
  Queue = "multiprocessing",
  RawValue = "multiprocessing",
  Semaphore = "multiprocessing",
  Value = "multiprocessing",

  import_module = "importlib",
  invalidate_caches = "importlib",
  reload = "importlib",

  BlockingIOError = "io",
  IOBase = "io",
  RawIOBase = "io",
  FileIO = "io",
  BytesIO = "io",
  StringIO = "io",
  BufferedIOBase = "io",
  BufferedReader = "io",
  BufferedWriter = "io",
  TextIOBase = "io",
  TextIOWrapper = "io",

  accumulate = "itertools",
  chain = "itertools",
  combinations = "itertools",
  combinations_with_replacement = "itertools",
  compress = "itertools",
  count = "itertools",
  cycle = "itertools",
  dropwhile = "itertools",
  filterfalse = "itertools",
  groupby = "itertools",
  islice = "itertools",
  pairwise = "itertools",
  permutations = "itertools",
  product = "itertools",
  ["repeat"] = "itertools",
  starmap = "itertools",
  takewhile = "itertools",
  tee = "itertools",
  zip_longest = "itertools",

  PathLike = "os",

  PurePath = "pathlib",
  PurePosixPath = "pathlib",
  PureWindowsPath = "pathlib",
  Path = "pathlib",
  PosixPath = "pathlib",
  WindowsPath = "pathlib",

  pprint = "pprint",
  pformat = "pprint",
  isreadable = "pprint",
  isrecursive = "pprint",
  saferepr = "pprint",
  PrettyPrinter = "pprint",
  pp = "pprint",

  Annotated = "typing",
  Annotation = "typing",
  Any = "typing", -- when you don't know the type
  Incomplete = "typing", -- alias for Any, but indicates that the type hint should be completed later
  Callable = "typing",
  ClassVar = "typing",
  Concatenate = "typing",
  Final = "typing",
  ForwardRef = "typing",
  Generic = "typing",
  Literal = "typing",
  Optional = "typing",
  ParamSpec = "typing",
  Protocol = "typing",
  Tuple = "typing",
  Type = "typing",
  TypeVar = "typing",
  TYPE_CHECKING = "typing",
  Union = "typing",
  AbstractSet = "typing",
  ByteString = "typing",
  Container = "typing",
  ContextManager = "typing",
  Hashable = "typing",
  ItemsView = "typing",
  Iterator = "typing",
  KeysView = "typing",
  Mapping = "typing",
  MappingView = "typing",
  MutableMapping = "typing",
  MutableSequence = "typing",
  MutableSet = "typing",
  Sized = "typing",
  ValuesView = "typing",
  Awaitable = "typing",
  AsyncIterator = "typing",
  AsyncIterable = "typing",
  Coroutine = "typing",
  Collection = "typing",
  AsyncGenerator = "typing",
  AsyncContextManager = "typing",
  Reversible = "typing",
  SupportsAbs = "typing",
  SupportsBytes = "typing",
  SupportsComplex = "typing",
  SupportsFloat = "typing",
  SupportsIndex = "typing",
  SupportsInt = "typing",
  SupportsRound = "typing",
  ChainMap = "typing",
  Counter = "typing",
  Deque = "typing",
  Dict = "typing",
  DefaultDict = "typing",
  List = "typing",
  Set = "typing",
  FrozenSet = "typing",
  NamedTuple = "typing",
  TypedDict = "typing",
  Generator = "typing",
  BinaryIO = "typing",
  IO = "typing",
  Match = "typing",
  Pattern = "typing",
  TextIO = "typing",
  AnyStr = "typing",
  NewType = "typing",
  NoReturn = "typing",
  ParamSpecArgs = "typing",
  ParamSpecKwargs = "typing",
  Text = "typing",
  TypeAlias = "typing",
  TypeGuard = "typing",
  override = "typing",
  overload = "typing",

  deprecated = "typing_extensions",

  setup = "setuptools",

  nn = "torch",
  Image = "PIL",
  ImageDraw = "PIL",
  ImageFont = "PIL",
  ImageOps = "PIL",
  tqdm = "tqdm.auto",
  EasyDict = "easydict",
  stringify_unsupported = "neptune.utils",
  Console = "rich.console",
  Table = "rich.table",
  Progress = "rich.progress",
  Traceback = "rich.traceback",
  Theme = "rich.theme",
  WebDriver = "selenium.webdriver.remote.webdriver",
  ic = "icecream",

  NDArray = "numpy.typing",
  ArrayLike = "numpy.typing",
  DTypeLike = "numpy.typing",
}

M.default_statement_after_imports = {
  logger = { "import logging", "", "logger = logging.getLogger(__name__)" },
}

M.python_keywords = {
  "False",
  "None",
  "True",
  "and",
  "as",
  "assert",
  "async",
  "await",
  "break",
  "class",
  "continue",
  "def",
  "del",
  "elif",
  "else",
  "except",
  "finally",
  "for",
  "from",
  "global",
  "if",
  "import",
  "in",
  "is",
  "lambda",
  "nonlocal",
  "not",
  "or",
  "pass",
  "raise",
  "return",
  "try",
  "while",
  "with",
  "yield",
  "NotImplemented",

  -- not a keyword, but commonly used
  "self",
}

-- not a keyword, but a builtin
-- https://docs.python.org/3/library/functions.html
M.python_builtins = {
  "abs",
  "aiter",
  "all",
  "anext",
  "any",
  "ascii",
  "bin",
  "bool",
  "breakpoint",
  "bytearray",
  "bytes",
  "callable",
  "chr",
  "classmethod",
  "compile",
  "complex",
  "delattr",
  "dict",
  "dir",
  "divmod",
  "enumerate",
  "eval",
  "exec",
  "filter",
  "float",
  "format",
  "frozenset",
  "getattr",
  "globals",
  "hasattr",
  "hash",
  "help",
  "hex",
  "id",
  "input",
  "int",
  "isinstance",
  "issubclass",
  "iter",
  "len",
  "list",
  "locals",
  "map",
  "max",
  "memoryview",
  "min",
  "next",
  "object",
  "oct",
  "open",
  "ord",
  "pow",
  "print",
  "property",
  "range",
  "repr",
  "reversed",
  "round",
  "set",
  "setattr",
  "slice",
  "sorted",
  "staticmethod",
  "str",
  "sum",
  "super",
  "tuple",
  "type",
  "vars",
  "zip",
  "__import__",
  "__build_class__",
  "__debug__",
  "__doc__",
  "__loader__",
  "__name__",
  "__package__",
  "__spec__",
  "__annotations__",
  "__dict__",
  "__dir__",
  "__file__",
  "__cached__",
  "_",
}

M.import = {} ---@type string[]
M.is_import = {} ---@type table<string, boolean>
-- for _, v in ipairs(M.import) do
--   M.is_import[v] = true
-- end

M.import_as = {} ---@type table<string, string>
M.import_from = {} ---@type table<string, string>
M.statement_after_imports = {} ---@type table<string, table<string>>

M.ban_from_import = {} ---@type table<string, boolean>
for _, v in ipairs(M.python_keywords) do
  M.ban_from_import[v] = true
end
for _, v in ipairs(M.python_builtins) do
  M.ban_from_import[v] = true
end

return M
