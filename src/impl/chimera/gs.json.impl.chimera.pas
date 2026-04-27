///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.chimera;

interface

uses sysutils,
     classes,
     gs.Json,
     chimera.json;

type

TgsJsonImplChimera = class(TInterfacedObject, igsJson)
private
protected
  FObj : IJSONObject;
  FArr : IJSONArray;
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

TgsJsonImplChimeraFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

// ---------------------------------------------------------------------------
// Helper : convert chimera TJSONValueType to TgsJsonElementType
// ---------------------------------------------------------------------------
function valueTypeToElementType(vt : TJSONValueType) : TgsJsonElementType;
begin
  case vt of
    TJSONValueType.null     : result := TgsJsonElementType.etNull;
    TJSONValueType.&string  : result := TgsJsonElementType.etString;
    TJSONValueType.number   : result := TgsJsonElementType.etNumber;
    TJSONValueType.boolean  : result := TgsJsonElementType.etBoolean;
    TJSONValueType.&object  : result := TgsJsonElementType.etJson;
    TJSONValueType.&array   : result := TgsJsonElementType.etJsonArray;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : ensure current wrapper is in Object mode
// ---------------------------------------------------------------------------
procedure ensureObj(var FObj : IJSONObject; var FArr : IJSONArray;
                    var FIsArray : boolean);
begin
  if FIsArray or (FObj = nil) then begin
    FObj := JSON();
    FArr := nil;
    FIsArray := false;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : ensure current wrapper is in Array mode
// ---------------------------------------------------------------------------
procedure ensureArr(var FObj : IJSONObject; var FArr : IJSONArray;
                    var FIsArray : boolean);
begin
  if (not FIsArray) or (FArr = nil) then begin
    FArr := JSONArray();
    FObj := nil;
    FIsArray := true;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : extract a sub-value into a new (or existing) igsJson wrapper
// without copying - shares the interface reference
// ---------------------------------------------------------------------------
procedure extractValue(srcObj : IJSONObject; srcArr : IJSONArray;
                       srcIsArray : boolean; var value : igsJson);
var
  w : TgsJsonImplChimera;
begin
  if not assigned(value) then
    value := TgsJsonImplChimera.Create;

  w := TgsJsonImplChimera(value);
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
// Helper : wrap a PMultiValue scalar into an igsJson wrapper
// We store the scalar as a single-key object using the empty string key "".
// This is the canonical way to carry a bare value through the igsJson layer
// since Chimera's current API has no IJSONObject.IsSimpleValue concept.
// ---------------------------------------------------------------------------
procedure wrapScalar(pv : PMultiValue; var value : igsJson);
var
  w   : TgsJsonImplChimera;
  obj : IJSONObject;
begin
  if not assigned(value) then
    value := TgsJsonImplChimera.Create;

  w := TgsJsonImplChimera(value);
  w.FOwned   := false;
  w.FIsArray := false;
  w.FArr     := nil;

  // Build a single-key wrapper object so the scalar survives round-trips
  obj := JSON();
  if pv = nil then begin
    obj.AddNull('');
  end else begin
    case pv^.ValueType of
      TJSONValueType.&string  : obj.Strings[''] := pv^.StringValue;
      TJSONValueType.number   : begin
        if pv^.NumberValue = Int64(pv^.IntegerValue) then
          obj.Integers[''] := pv^.IntegerValue
        else
          obj.Numbers['']  := pv^.NumberValue;
      end;
      TJSONValueType.boolean  : obj.Booleans[''] := (pv^.IntegerValue <> 0);
      TJSONValueType.null     : obj.AddNull('');
    else
      obj.AddNull('');
    end;
  end;

  w.FObj := obj;
end;

// ---------------------------------------------------------------------------
// Helper : detect whether an IJSONObject is a scalar wrapper
// (single entry with key = ''), as produced by wrapScalar above.
// ---------------------------------------------------------------------------
function isBareWrapper(obj : IJSONObject) : boolean;
begin
  result := (obj <> nil) and (obj.Count = 1) and (obj.Names[0] = '');
end;

// ---------------------------------------------------------------------------
// Helper : add array-of-const elements to an IJSONArray
// ---------------------------------------------------------------------------
procedure addToArray(arr : IJSONArray; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : arr.Add(String(vals[i].VString^));
      vtWideString    : arr.Add(String(vals[i].VWideString));
      vtUnicodeString : arr.Add(UnicodeString(vals[i].VUnicodeString));
      vtInteger       : arr.Add(Int64(vals[i].VInteger));
      System.vtBoolean: arr.Add(vals[i].VBoolean);
      vtExtended      : arr.Add(Double(vals[i].VExtended^));
      vtInt64         : arr.Add(vals[i].VInt64^);
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : add a parsed sub-json string to an IJSONArray
// Handles objects, arrays, and scalar bare values.
// ---------------------------------------------------------------------------
procedure addParsedToArray(arr : IJSONArray; const trimmed : string);
begin
  if trimmed = '' then
    exit;
  if trimmed[1] = '[' then
    arr.Add(JSONArray(trimmed))
  else if trimmed[1] = '{' then
    arr.Add(JSON(trimmed))
  else if SameText(trimmed, 'null') then
    arr.AddNull
  else if SameText(trimmed, 'true') then
    arr.Add(true)
  else if SameText(trimmed, 'false') then
    arr.Add(false)
  else begin
    // Try numeric, fall back to string (strip surrounding quotes if present)
    var dval : double;
    var ival : int64;
    if TryStrToInt64(trimmed, ival) then
      arr.Add(ival)
    else if TryStrToFloat(trimmed, dval) then
      arr.Add(dval)
    else begin
      // Strip optional surrounding quotes from a bare string value
      if (Length(trimmed) >= 2) and (trimmed[1] = '"') and (trimmed[Length(trimmed)] = '"') then
        arr.Add(JSONDecode(Copy(trimmed, 2, Length(trimmed) - 2)))
      else
        arr.Add(trimmed);
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Helper : put a parsed sub-json string as a named key in an IJSONObject
// ---------------------------------------------------------------------------
procedure putParsedToObj(obj : IJSONObject; const name, trimmed : string);
begin
  if trimmed = '' then
    exit;
  if trimmed[1] = '[' then
    obj.Arrays[name] := JSONArray(trimmed)
  else if trimmed[1] = '{' then
    obj.Objects[name] := JSON(trimmed)
  else if SameText(trimmed, 'null') then
    obj.AddNull(name)
  else if SameText(trimmed, 'true') then
    obj.Booleans[name] := true
  else if SameText(trimmed, 'false') then
    obj.Booleans[name] := false
  else begin
    var dval : double;
    var ival : int64;
    if TryStrToInt64(trimmed, ival) then
      obj.Integers[name] := ival
    else if TryStrToFloat(trimmed, dval) then
      obj.Numbers[name] := dval
    else begin
      if (Length(trimmed) >= 2) and (trimmed[1] = '"') and (trimmed[Length(trimmed)] = '"') then
        obj.Strings[name] := JSONDecode(Copy(trimmed, 2, Length(trimmed) - 2))
      else
        obj.Strings[name] := trimmed;
    end;
  end;
end;

{ TgsJsonImplChimera }

constructor TgsJsonImplChimera.Create;
begin
  FObj := nil;
  FArr := nil;
  FIsArray := false;
  FOwned := true;
end;

destructor TgsJsonImplChimera.Destroy;
begin
  FObj := nil;
  FArr := nil;
  inherited;
end;

function TgsJsonImplChimera.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
begin
  result := self;
  trimmed := Trim(aJsonStr);
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');

  FIsArray := false;
  FArr     := nil;
  FObj     := nil;
  FOwned   := true;

  if trimmed[1] = '[' then begin
    // Standard JSON array
    FArr     := JSONArray(trimmed);
    FIsArray := true;
  end else if trimmed[1] = '{' then begin
    // Standard JSON object
    FObj := JSON(trimmed);
  end else begin
    // Bare scalar value (number, boolean, null, quoted string).
    // Wrap it as a single-key object so igsJson can carry it uniformly.
    var pv : TMultiValue;
    if SameText(trimmed, 'null') then
      pv.InitializeNull
    else if SameText(trimmed, 'true') then
      pv.Initialize(true)
    else if SameText(trimmed, 'false') then
      pv.Initialize(false)
    else begin
      var ival : int64;
      var dval : double;
      if TryStrToInt64(trimmed, ival) then
        pv.Initialize(ival)
      else if TryStrToFloat(trimmed, dval) then
        pv.Initialize(dval)
      else begin
        // Quoted string: strip surrounding quotes
        if (Length(trimmed) >= 2) and (trimmed[1] = '"') and (trimmed[Length(trimmed)] = '"') then
          pv.Initialize(JSONDecode(Copy(trimmed, 2, Length(trimmed) - 2)))
        else
          pv.Initialize(trimmed);
      end;
    end;
    FObj := JSON();
    FObj.Add('', @pv);
  end;
end;

function TgsJsonImplChimera.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.Numbers[name] := val;
end;

function TgsJsonImplChimera.put(name, val: string): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.Strings[name] := val;
end;

function TgsJsonImplChimera.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  FObj.Booleans[name] := val;
end;

function TgsJsonImplChimera.put(vals: array of const): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  addToArray(FArr, vals);
end;

function TgsJsonImplChimera.put(name: string; vals: array of const): igsJson;
var
  arr : IJSONArray;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  arr := JSONArray();
  addToArray(arr, vals);
  FObj.Arrays[name] := arr;
end;

function TgsJsonImplChimera.put(name: string; val: igsJson): igsJson;
var
  js, trimmed : string;
begin
  result := self;
  ensureObj(FObj, FArr, FIsArray);
  js := val.stringify;
  trimmed := Trim(js);
  putParsedToObj(FObj, name, trimmed);
end;

function TgsJsonImplChimera.put(val: igsJson): igsJson;
var
  js, trimmed : string;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  js := val.stringify;
  trimmed := Trim(js);
  addParsedToArray(FArr, trimmed);
end;

function TgsJsonImplChimera.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FIsArray then begin
    if FArr <> nil then
      FArr.AsJSON(aStr)
    else
      aStr := '[]';
  end else begin
    if FObj <> nil then begin
      // If this is a bare-value wrapper (single key ''), emit only the raw value
      if isBareWrapper(FObj) then begin
        var pv := FObj.Raw[''];
        if pv <> nil then
          pv^.AsJSON(aStr)
        else
          aStr := 'null';
      end else
        FObj.AsJSON(aStr);
    end else
      aStr := 'null';
  end;
end;

function TgsJsonImplChimera.stringify: string;
begin
  result := '';
  stringify(result);
end;

function TgsJsonImplChimera.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if not FObj.Has[name] then
    raise Exception.Create('TgsJsonImplChimera.get: Key not found: ' + name);
  value := FObj.Strings[name];
end;

function TgsJsonImplChimera.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Count);
    value := FArr.Strings[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    value := FObj.Strings[FObj.Names[index]];
  end;
end;

function TgsJsonImplChimera.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  value := Integer(FObj.Integers[name]);
end;

function TgsJsonImplChimera.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Count);
    value := Integer(FArr.Integers[index]);
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    value := Integer(FObj.Integers[FObj.Names[index]]);
  end;
end;

function TgsJsonImplChimera.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  value := FObj.Numbers[name];
end;

function TgsJsonImplChimera.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Count);
    value := FArr.Numbers[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    value := FObj.Numbers[FObj.Names[index]];
  end;
end;

function TgsJsonImplChimera.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  value := FObj.Booleans[name];
end;

function TgsJsonImplChimera.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Count);
    value := FArr.Booleans[index];
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    value := FObj.Booleans[FObj.Names[index]];
  end;
end;

function TgsJsonImplChimera.get(name: string; var value: igsJson): igsJson;
var
  vt : TJSONValueType;
begin
  result := self;
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.get: Not an object');
  if not FObj.Has[name] then
    raise Exception.Create('TgsJsonImplChimera.get: Key not found: ' + name);

  vt := FObj.Types[name];
  case vt of
    TJSONValueType.&object :
      extractValue(FObj.Objects[name], nil, false, value);
    TJSONValueType.&array :
      extractValue(nil, FObj.Arrays[name], true, value);
  else
    // Scalar : wrap via PMultiValue (Raw[] accessor, always available)
    wrapScalar(FObj.Raw[name], value);
  end;
end;

function TgsJsonImplChimera.get(index: integer; var value: igsJson): igsJson;
var
  vt : TJSONValueType;
begin
  result := self;
  if FIsArray then begin
    assert(FArr <> nil);
    assert(index < FArr.Count);
    vt := FArr.Types[index];
    case vt of
      TJSONValueType.&object :
        extractValue(FArr.Objects[index], nil, false, value);
      TJSONValueType.&array :
        extractValue(nil, FArr.Arrays[index], true, value);
    else
      wrapScalar(FArr.Raw[index], value);
    end;
  end else begin
    assert(FObj <> nil);
    assert(index < FObj.Count);
    get(FObj.Names[index], value);
  end;
end;

function TgsJsonImplChimera.jsonElementCount: integer;
begin
  if FIsArray then begin
    if FArr <> nil then
      result := FArr.Count
    else
      result := 0;
  end else begin
    if FObj <> nil then begin
      // A bare-value wrapper has no meaningful child elements
      if isBareWrapper(FObj) then
        result := -1
      else
        result := FObj.Count;
    end else
      result := -1;
  end;
end;

function TgsJsonImplChimera.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FIsArray then begin
    if (FArr <> nil) and (index < FArr.Count) then
      result := valueTypeToElementType(FArr.Types[index]);
  end else begin
    if (FObj <> nil) and (not isBareWrapper(FObj)) and (index < FObj.Count) then
      result := valueTypeToElementType(FObj.Types[FObj.Names[index]]);
  end;
end;

function TgsJsonImplChimera.jsonType: TgsJsonElementType;
begin
  if FIsArray then
    result := TgsJsonElementType.etJsonArray
  else if FObj <> nil then begin
    if isBareWrapper(FObj) then
      // Return the actual scalar type stored under key ''
      result := valueTypeToElementType(FObj.Types[''])
    else
      result := TgsJsonElementType.etJson;
  end else
    result := TgsJsonElementType.etEmpty;
end;

function TgsJsonImplChimera.jsonElementName(index: integer): string;
begin
  result := '';
  if FIsArray then
    raise Exception.Create('TgsJsonImplChimera.jsonElementName: Not an object');
  if FObj = nil then
    raise Exception.Create('TgsJsonImplChimera.jsonElementName: Not an object');
  assert(index < FObj.Count);
  result := FObj.Names[index];
end;

function TgsJsonImplChimera.clear: igsJson;
begin
  result := self;
  FObj := nil;
  FArr := nil;
  FIsArray := false;
  FOwned := true;
end;

function TgsJsonImplChimera.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplChimera.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplChimera.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplChimera.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplChimera.asObj(name: String): igsJson;
begin
  result := nil;
  get(name, result);
end;

function TgsJsonImplChimera.asObj(index: integer): igsJson;
begin
  result := nil;
  get(index, result);
end;

function TgsJsonImplChimera.add(val: igsJson): igsJson;
var
  trimmed : string;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  trimmed := Trim(val.stringify);
  addParsedToArray(FArr, trimmed);
end;

function TgsJsonImplChimera.add(val: double): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(val);
end;

function TgsJsonImplChimera.add(val: integer): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Int64(val));
end;

function TgsJsonImplChimera.add(val: string): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(val);
end;

function TgsJsonImplChimera.add(val: byte): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(Int64(val));
end;

function TgsJsonImplChimera.add(val: boolean): igsJson;
begin
  result := self;
  ensureArr(FObj, FArr, FIsArray);
  FArr.Add(val);
end;

function TgsJsonImplChimera.isNameExists(name: String): boolean;
begin
  result := false;
  if (not FIsArray) and (FObj <> nil) and (not isBareWrapper(FObj)) then
    result := FObj.Has[name];
end;

function TgsJsonImplChimera.ToObj: igsJson;
begin
  result := self;
  if FIsArray or (FObj = nil) then begin
    FObj := JSON();
    FArr := nil;
    FIsArray := false;
  end;
end;

function TgsJsonImplChimera.ToArray: igsJson;
begin
  result := self;
  if (not FIsArray) or (FArr = nil) then begin
    FArr := JSONArray();
    FObj := nil;
    FIsArray := true;
  end;
end;

{ TgsJsonImplChimeraFactory }

function TgsJsonImplChimeraFactory.getAuthor: string;
begin
  result := 'Sivv LLC (Arcana)';
end;

function TgsJsonImplChimeraFactory.getTitle: string;
begin
  result := 'Chimera JSON';
end;

function TgsJsonImplChimeraFactory.getDesc: string;
begin
  result := 'Chimera JSON - Interface-based JSON for Delphi';
end;

function TgsJsonImplChimeraFactory.getId: string;
begin
  result := 'chimera';
end;

function TgsJsonImplChimeraFactory.getJson: igsJson;
begin
  result := TgsJsonImplChimera.Create;
end;

initialization

addImplementation(TgsJsonImplChimeraFactory.Create);

end.
