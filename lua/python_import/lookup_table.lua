M = {}

-- If nothing is found, it will return `import ..` anyway.
-- However, it might take some time to search the candidate,
-- so we define a list of common imports here.
---@type string[]
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
  "subprocess",
  "xml",

  -- third-party
  "PIL",
  "easydict",
  "rich",
  "selenium",
  "neptune",
  "torch",
}

---@type table<string, string>
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

---@type table<string, string>
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

  Callable = "collections.abc",
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
  StrEnum = "enum",

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
  overload = "typing",

  override = "typing_extensions", -- in typing since Python 3.12
  deprecated = "typing_extensions", -- in warnings since Python 3.13
  Self = "typing_extensions", -- in typing since Python 3.11
  TypedDict = "typing_extensions",
  NotRequired = "typing_extensions", -- in typing since Python 3.11
  Required = "typing_extensions", -- in typing since Python 3.11

  setup = "setuptools",

  Popen = "subprocess",
  PIPE = "subprocess",
  STDOUT = "subprocess",
  DEVNULL = "subprocess",
  SubprocessError = "subprocess",
  CalledProcessError = "subprocess",
  CompletedProcess = "subprocess",

  -- third-party
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
  Confirm = "rich.prompt",
  Prompt = "rich.prompt",
  Syntax = "rich.syntax",
  WebDriver = "selenium.webdriver.remote.webdriver",
  ic = "icecream",
  sql = "psycopg",

  NDArray = "numpy.typing",
  ArrayLike = "numpy.typing",
  DTypeLike = "numpy.typing",

  BaseModel = "pydantic",
  Field = "pydantic",
  ValidationError = "pydantic",
  ValidationInfo = "pydantic",
  ValidatorFunctionWrapHandler = "pydantic",
  AfterValidator = "pydantic.functional_validators",
  BeforeValidator = "pydantic.functional_validators",
  WrapValidator = "pydantic.functional_validators",
  InstanceOf = "pydantic.functional_validators",
  SkipValidation = "pydantic.functional_validators",
  field_validator = "pydantic.functional_validators",
  model_validator = "pydantic.functional_validators",
  ConfigDict = "pydantic.config",

  PositiveInt = "pydantic.types",
  NegativeInt = "pydantic.types",
  PositiveFloat = "pydantic.types",
  NegativeFloat = "pydantic.types",
  FilePath = "pydantic.types",
  DirectoryPath = "pydantic.types",
  PastDate = "pydantic.types",
  FutureDate = "pydantic.types",
  EmailStr = "pydantic.types",
  NameEmail = "pydantic.types",
  PyObject = "pydantic.types",
  Color = "pydantic.types",
  Json = "pydantic.types",
  PaymentCardNumber = "pydantic.types",
  AnyUrl = "pydantic.types",
  AnyHttpUrl = "pydantic.types",
  HttpUrl = "pydantic.types",
  FileUrl = "pydantic.types",
  PostgresDsn = "pydantic.types",
  CockroachDsn = "pydantic.types",
  AmqpDsn = "pydantic.types",
  RedisDsn = "pydantic.types",
  MongoDsn = "pydantic.types",
  KafkaDsn = "pydantic.types",
  stricturl = "pydantic.types",
  UUID1 = "pydantic.types",
  UUID3 = "pydantic.types",
  UUID4 = "pydantic.types",
  UUID5 = "pydantic.types",
  SecretBytes = "pydantic.types",
  SecretStr = "pydantic.types",
  IPvAnyAddress = "pydantic.types",
  IPvAnyInterface = "pydantic.types",
  IPvAnyNetwork = "pydantic.types",
  conbytes = "pydantic.types",
  condecimal = "pydantic.types",
  confloat = "pydantic.types",
  conint = "pydantic.types",
  condate = "pydantic.types",
  conlist = "pydantic.types",
  conset = "pydantic.types",
  confrozenset = "pydantic.types",
  constr = "pydantic.types",

  -- bioinformatics
  pybel = "openbabel",
}

---@type table<string, table<string>>
M.default_statement_after_imports = {
  logger = { "import logging", "", "logger = logging.getLogger(__name__)" },

  -- third-party
  -- bioinformatics
  ob = { "from openbabel import openbabel as ob" },
}

---@type string[]
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
---@type string[]
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
