///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.xSuperObject;

interface

uses sysutils,
     classes,
     gs.Json,
     XSuperJSON,
     XSuperObject;

type

TgsJsonImplXSuperObject = class(TInterfacedObject, igsJson)
private
protected
  FObj : ISuperObject;
  FArr : ISuperArray;
  FIsArray : boolean;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  //Array
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

  //Add an object.
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;

  function get(name : string; var value : integer) : igsJson; overload;
  function get(index : integer; var value : integer) : igsJson; overload;

  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;

  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;

  //Object / Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  //Analyses.
  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  //Base type easy access.
  function asString(name : String) : string;
  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload;
  function asObj(index : integer) : igsJson; overload;

  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;

  function isNameExists(name: String): boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;

TgsJsonImplXSuperObjectFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

uses Variants;

// ---------------------------------------------------------------------------
// Helper : convert XSuperObject TDataType to TgsJsonElementType
// ---------------------------------------------------------------------------
function dataTypeToElementType(dt : TDataType) : TgsJsonElementType;
begin
  case dt of
    dtNull     : result := TgsJsonElementType.etNull;
    dtString   : result := TgsJsonElementType.etString;
    dtInteger  : result := TgsJsonElementType.etNumber;
    dtFloat    : result := TgsJsonElementType.etNumber;
    dtBoolean  : result := TgsJsonElementType.etBoolean;
    dtObject   : result := TgsJsonElementType.etJson;
    dtArray    : result := TgsJsonElementType.etJsonArray;
    dtDateTime : result := TgsJsonElementType.etString;
    dtDate     : result := TgsJsonElementType.etString;
    dtTime     : result := TgsJsonElementType.etString;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : convert an IJSONAncestor value to TgsJsonElementType
// ---------------------------------------------------------------------------
function ancestorToElementType(anc : IJSONAncestor) : TgsJsonElementType;
begin
  if anc = nil then
    exit(TgsJsonElementType.etEmpty);
  result := dataTypeToElementType(anc.DataType);
end;

// ---------------------------------------------------------------------------
// Helper : ensure current wrapper is in Object mode
// ---------------------------------------------------------------------------
procedure ensureObj(var FObj : ISuperObject; var FArr : ISuperArray;
                    var FIsArray : boolean);
begin
  if FIsArray or (FObj = nil) then begin
    FObj := SO('{}');
    FArr := nil;
    FIsArray := false;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : ensure current wrapper is in Array mode
// ---------------------------------------------------------------------------
procedure ensureArr(var FObj : ISuperObject; var FArr : ISuperArray;
                    var FIsArray : boolean);
begin
  if (not FIsArray) or (FArr = nil) then begin
    FArr := SA('[]');
    FObj := nil;
    FIsArray := true;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : extract a sub-value into a new (or existing) igsJson wrapper
// ---------------------------------------------------------------------------
procedure extractValue(srcObj : ISuperObject; srcArr : ISuperArray;
                       srcIsArray : boolean; var value : igsJson);
var
  w : TgsJsonImplXSuperObject;
begin
  if not assigned(value) then
    value := TgsJsonImplXSuperObject.Create;

  w := TgsJsonImplXSuperObject(value);
  w.FOwned := false;

  if srcIsArray then begin
    w.FObj := nil;
    w.FArr := srcArr;
    w.FIsArray := true;
  end else begin
    w.FObj := srcObj;
    w.FArr := nil;
    w.FIsArray := false;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : add array-of-const elements to an ISuperArray
// ---------------------------------------------------------------------------
procedure addToArray(arr : ISuperArray; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : arr.Add(Variant(String(vals[i].VString^)));
      vtWideString    : arr.Add(Variant(String(vals[i].VWideString)));
      vtUnicodeString : arr.Add(Variant(UnicodeString(vals[i].VUnicodeString)));
      vtInteger       : arr.Add(Variant(vals[i].VInteger));
      vtBoolean       : arr.Add(Variant(vals[i].VBoolean));
      vtExtended      : arr.Add(Variant(vals[i].VExtended^));
      vtInt64         : arr.Add(Variant(vals[i].VInt64^));
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : get element type at index from an ISuperObject (by iterating)
// ---------------------------------------------------------------------------
function getObjAncestorAtIndex(obj : ISuperObject; index : integer) : IJSONAncestor;
var
  i : integer;
begin
  result := nil;
  obj.First;
  i := 0;
  while not obj.EoF do begin
    if i = index then begin
      result := obj.CurrentValue;
      exit;
    end;
    obj.Next;
    inc(i);
  end;
end;


{ TgsJsonImplXSuperObject }

constructor TgsJsonImplXSuperObject.Create;
begin
  FObj := nil;
  FArr := nil;
  FIsArray := false;
  FOwned := true;
end;

destructor TgsJsonImplXSuperObject.Destroy;
begin
  FObj := nil;
  FArr := nil;
  inherited;
end;

function TgsJsonImplXSuperObject.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
begin
  result := self;
  trimmed := Trim(aJsonStr);
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');

  // Determine if it's an array or object
  if (trimmed[1] = '[') then begin
    FArr := SA(trimmed);
    FObj := nil;
    FIsArray := true;
  end else if (trimmed[1] = '{') then begin
    FObj := SO(trimmed);
    FArr := nil;
    FIsArray := false;
  end else begin
    // Bare value: try to wrap in an object context via SO
    // XSuperObject does not handle bare values natively - wrap and unwrap
    // Try parsing as a single-element to detect type
    // Use the SO helper to wrap: {"_":value}
    var wrapped := '{"_":' + trimmed + '}';
    try
      var tmpObj := SO(wrapped);
      // Now extract the ancestor for key "_" to determine the type
      // We store as a "casted" object that contains a single key
      FObj := tmpObj;
      FArr := nil;
      FIsArray := false;
    except
      raise JsonException.Create('JSON parse error: ' + aJsonStr);
    end;
  end;

  FOwned := true;
end;

function TgsJsonImplXSuperObject.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.F[name] := val;
end;

function TgsJsonImplXSuperObject.put(name, val: string): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.S[name] := val;
end;

function TgsJsonImplXSuperObject.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.B[name] := val;
end;

function TgsJsonImplXSuperObject.put(vals: array of const): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  addToArray(FArr, vals);
end;

function TgsJsonImplXSuperObject.put(name: string; vals: array of const): igsJson;
var
  arr : ISuperArray;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  arr := SA('[]');
  addToArray(arr, vals);
  FObj.A[name] := arr;
end;

function TgsJsonImplXSuperObject.put(name: string; val: igsJson): igsJson;
var
  js : string;
  trimmed : string;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  js := val.stringify;
  trimmed := Trim(js);
  if (trimmed <> '') and (trimmed[1] = '[') then
    FObj.A[name] := SA(js)
  else
    FObj.O[name] := SO(js);
end;

function TgsJsonImplXSuperObject.put(val: igsJson): igsJson;
var
  js : string;
  trimmed : string;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  js := val.stringify;
  trimmed := Trim(js);
  if (trimmed <> '') and (trimmed[1] = '[') then
    FArr.Add(SA(js))
  else
    FArr.Add(SO(js));
end;

function TgsJsonImplXSuperObject.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FIsArray then begin
    if FArr <> nil then
      aStr := FArr.AsJSON
    else
      aStr := '[]';
  end else begin
    if FObj <> nil then
      aStr := FObj.AsJSON
    else
      aStr := 'null';
  end;
end;

function TgsJsonImplXSuperObject.stringify: string;
begin
  if FIsArray then begin
    if FArr <> nil then
      result := FArr.AsJSON
    else
      result := '[]';
  end else begin
    if FObj <> nil then
      result := FObj.AsJSON
    else
      result := 'null';
  end;
end;

function TgsJsonImplXSuperObject.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if not FObj.Contains(name) then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Key not found: ' + name);
  value := FObj.S[name];
end;

function TgsJsonImplXSuperObject.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Length);
    value := FArr.S[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    // Iterate to index-th element
    FObj.First;
    var i := 0;
    while not FObj.EoF do begin
      if i = index then begin
        value := FObj.S[FObj.CurrentKey];
        exit;
      end;
      FObj.Next;
      inc(i);
    end;
  end;
end;

function TgsJsonImplXSuperObject.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  value := Integer(FObj.I[name]);
end;

function TgsJsonImplXSuperObject.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Length);
    value := Integer(FArr.I[index]);
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    FObj.First;
    var i := 0;
    while not FObj.EoF do begin
      if i = index then begin
        value := Integer(FObj.I[FObj.CurrentKey]);
        exit;
      end;
      FObj.Next;
      inc(i);
    end;
  end;
end;

function TgsJsonImplXSuperObject.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  value := FObj.F[name];
end;

function TgsJsonImplXSuperObject.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Length);
    value := FArr.F[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    FObj.First;
    var i := 0;
    while not FObj.EoF do begin
      if i = index then begin
        value := FObj.F[FObj.CurrentKey];
        exit;
      end;
      FObj.Next;
      inc(i);
    end;
  end;
end;

function TgsJsonImplXSuperObject.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  value := FObj.B[name];
end;

function TgsJsonImplXSuperObject.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Length);
    value := FArr.B[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    FObj.First;
    var i := 0;
    while not FObj.EoF do begin
      if i = index then begin
        value := FObj.B[FObj.CurrentKey];
        exit;
      end;
      FObj.Next;
      inc(i);
    end;
  end;
end;

function TgsJsonImplXSuperObject.get(name: string; var value: igsJson): igsJson;
var
  anc : IJSONAncestor;
  subObj : ISuperObject;
  subArr : ISuperArray;
begin
  result := self;
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Not an object');
  if not FObj.Contains(name) then
    raise JsonException.Create('TgsJsonImplXSuperObject.get: Key not found: ' + name);

  // Determine if the value is an object or array via GetType
  var vt := FObj.GetType(name);
  if vt = varArray then begin
    subArr := FObj.A[name];
    extractValue(nil, subArr, true, value);
  end else if vt = varObject then begin
    subObj := FObj.O[name];
    extractValue(subObj, nil, false, value);
  end else begin
    // Scalar value - wrap in a temp object containing just this key
    // so that stringify returns the scalar's JSON representation
    subObj := SO('{"_":' + FObj.Raw[name] + '}');
    // Actually, let's just re-parse the raw value into a new object
    // For scalar sub-values, create a minimal wrapper
    var w : TgsJsonImplXSuperObject;
    if not assigned(value) then
      value := TgsJsonImplXSuperObject.Create;
    w := TgsJsonImplXSuperObject(value);
    w.FOwned := false;
    // Store the whole parent object and let the caller use get() on result
    // This is consistent with bero wrapper which points to the raw item
    // For XSuperObject, we re-parse the raw value
    var rawVal := FObj.Raw[name];
    try
      value.parse(rawVal);
    except
      // Bare value that can't be parsed - wrap it
      w.FObj := SO('{"_":' + rawVal + '}');
      w.FArr := nil;
      w.FIsArray := false;
    end;
  end;
end;

function TgsJsonImplXSuperObject.get(index: integer; var value: igsJson): igsJson;
var
  subObj : ISuperObject;
  subArr : ISuperArray;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Length);
    var anc := FArr.Ancestor[index];
    if anc = nil then begin
      if not assigned(value) then
        value := TgsJsonImplXSuperObject.Create;
      exit;
    end;
    case anc.DataType of
      dtArray : begin
        subArr := FArr.A[index];
        extractValue(nil, subArr, true, value);
      end;
      dtObject : begin
        subObj := FArr.O[index];
        extractValue(subObj, nil, false, value);
      end;
    else
      // Scalar in array - wrap as object with single key
      if not assigned(value) then
        value := TgsJsonImplXSuperObject.Create;
      var w := TgsJsonImplXSuperObject(value);
      w.FOwned := false;
      // Re-parse the element: use the Cast interface to get its string
      var cast := FArr.Ancestor[index];
      if cast <> nil then begin
        var writer := TJSONWriter.Create(false, false);
        try
          cast.AsJSONString(writer);
          var rawStr := writer.ToString;
          try
            value.parse(rawStr);
          except
            w.FObj := SO('{"_":' + rawStr + '}');
            w.FArr := nil;
            w.FIsArray := false;
          end;
        finally
          writer.Free;
        end;
      end;
    end;
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    // Get key at index
    var key := jsonElementName(index);
    get(key, value);
  end;
end;

function TgsJsonImplXSuperObject.jsonElementCount: integer;
begin
  if FIsArray then begin
    if FArr <> nil then
      result := FArr.Length
    else
      result := 0;
  end else begin
    if FObj <> nil then
      result := FObj.Count
    else
      result := -1;
  end;
end;

function TgsJsonImplXSuperObject.jsonElementType(index: integer): TgsJsonElementType;
var
  anc : IJSONAncestor;
begin
  result := TgsJsonElementType.etEmpty;
  if FIsArray then begin
    if (FArr <> nil) and (index < FArr.Length) then begin
      anc := FArr.Ancestor[index];
      if anc <> nil then
        result := ancestorToElementType(anc);
    end;
  end else begin
    if (FObj <> nil) and (index < FObj.Count) then begin
      anc := getObjAncestorAtIndex(FObj, index);
      if anc <> nil then
        result := ancestorToElementType(anc);
    end;
  end;
end;

function TgsJsonImplXSuperObject.jsonType: TgsJsonElementType;
begin
  if FIsArray then
    result := TgsJsonElementType.etJsonArray
  else if FObj <> nil then
    result := TgsJsonElementType.etJson
  else
    result := TgsJsonElementType.etEmpty;
end;

function TgsJsonImplXSuperObject.jsonElementName(index: integer): string;
var
  i : integer;
begin
  result := '';
  if FIsArray then
    raise JsonException.Create('TgsJsonImplXSuperObject.jsonElementName: Not an object');
  if FObj = nil then
    raise JsonException.Create('TgsJsonImplXSuperObject.jsonElementName: Not an object');
  assert(index < FObj.Count);

  FObj.First;
  i := 0;
  while not FObj.EoF do begin
    if i = index then begin
      result := FObj.CurrentKey;
      exit;
    end;
    FObj.Next;
    inc(i);
  end;
end;

function TgsJsonImplXSuperObject.clear: igsJson;
begin
  result := self;
  FObj := nil;
  FArr := nil;
  FIsArray := false;
  FOwned := true;
end;

function TgsJsonImplXSuperObject.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplXSuperObject.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplXSuperObject.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplXSuperObject.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplXSuperObject.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplXSuperObject.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplXSuperObject.add(val: igsJson): igsJson;
var
  js, trimmed : string;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  js := val.stringify;
  trimmed := Trim(js);
  if (trimmed <> '') and (trimmed[1] = '[') then
    FArr.Add(SA(js))
  else if (trimmed <> '') and (trimmed[1] = '{') then
    FArr.Add(SO(js))
  else
    FArr.Add(Variant(js));
end;

function TgsJsonImplXSuperObject.add(val: double): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Variant(val));
end;

function TgsJsonImplXSuperObject.add(val: integer): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Variant(val));
end;

function TgsJsonImplXSuperObject.add(val: string): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Variant(val));
end;

function TgsJsonImplXSuperObject.add(val: byte): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Variant(Integer(val)));
end;

function TgsJsonImplXSuperObject.add(val: boolean): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Variant(val));
end;

function TgsJsonImplXSuperObject.isNameExists(name: String): boolean;
begin
  result := false;
  if (not FIsArray) and (FObj <> nil) then
    result := FObj.Contains(name);
end;

function TgsJsonImplXSuperObject.ToObj: igsJson;
begin
  result := self;
  if FIsArray or (FObj = nil) then begin
    FObj := SO('{}');
    FArr := nil;
    FIsArray := false;
  end;
end;

function TgsJsonImplXSuperObject.ToArray: igsJson;
begin
  result := self;
  if (not FIsArray) or (FArr = nil) then begin
    FArr := SA('[]');
    FObj := nil;
    FIsArray := true;
  end;
end;


{ TgsJsonImplXSuperObjectFactory }

function TgsJsonImplXSuperObjectFactory.getAuthor: string;
begin
  result := 'Onur YILDIZ';
end;

function TgsJsonImplXSuperObjectFactory.getTitle: string;
begin
  result := 'XSuperObject';
end;

function TgsJsonImplXSuperObjectFactory.getDesc: string;
begin
  result := 'XSuperObject - Simple JSON Framework';
end;

function TgsJsonImplXSuperObjectFactory.getId: string;
begin
  result := 'xsuperobject';
end;

function TgsJsonImplXSuperObjectFactory.getJson: igsJson;
begin
  result := TgsJsonImplXSuperObject.Create;
end;

initialization

addImplementation(TgsJsonImplXSuperObjectFactory.Create);

end.
