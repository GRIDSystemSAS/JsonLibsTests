///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.neslibJson;

interface

uses sysutils,
     classes,
     gs.Json,
     Neslib.Json;

type

TgsJsonImplNeslibJson = class(TInterfacedObject, igsJson)
private
protected
  FDoc : IJsonDocument;
  FOwned : boolean;
  // For bare values (number, string, boolean, null) that Neslib.Json cannot
  // represent as a document, we store them separately.
  FBareValue : string;
  FBareType  : TgsJsonElementType; // etEmpty means we use FDoc
  procedure EnsureDict;
  procedure EnsureArray;
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

TgsJsonImplNeslibJsonFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

uses Neslib.Json.Types;

{ Helpers }

function NeslibValueToElementType(const AValue: TJsonValue): TgsJsonElementType;
begin
  case AValue.ValueType of
    TJsonValueType.Null       : result := TgsJsonElementType.etNull;
    TJsonValueType.Boolean    : result := TgsJsonElementType.etBoolean;
    TJsonValueType.Ordinal    : result := TgsJsonElementType.etNumber;
    TJsonValueType.Float      : result := TgsJsonElementType.etNumber;
    TJsonValueType.&String    : result := TgsJsonElementType.etString;
    TJsonValueType.&Array     : result := TgsJsonElementType.etJsonArray;
    TJsonValueType.Dictionary : result := TgsJsonElementType.etJson;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

procedure ExtractNeslibValue(ADoc: IJsonDocument; AValue: TJsonValue;
  var value: igsJson);
var
  child : TgsJsonImplNeslibJson;
  childJson : string;
begin
  if not assigned(value) then
    value := TgsJsonImplNeslibJson.Create;

  child := TgsJsonImplNeslibJson(value);

  // For compound types (object/array), re-serialize and re-parse so each
  // igsJson instance owns its own IJsonDocument.
  if AValue.IsDictionary or AValue.IsArray then begin
    childJson := AValue.ToJson(False);
    child.FDoc := TJsonDocument.Parse(childJson);
    child.FBareType := TgsJsonElementType.etEmpty;
    child.FOwned := true;
  end
  else begin
    // Bare value: store in FBareValue/FBareType
    child.FDoc := nil;
    child.FOwned := true;
    if AValue.IsNull then begin
      child.FBareType := TgsJsonElementType.etNull;
      child.FBareValue := 'null';
    end
    else if AValue.IsBoolean then begin
      child.FBareType := TgsJsonElementType.etBoolean;
      if AValue.ToBoolean then
        child.FBareValue := 'true'
      else
        child.FBareValue := 'false';
    end
    else if AValue.IsString then begin
      child.FBareType := TgsJsonElementType.etString;
      child.FBareValue := AValue.ToString;
    end
    else if AValue.IsNumeric then begin
      child.FBareType := TgsJsonElementType.etNumber;
      child.FBareValue := AValue.ToJson(False);
    end
    else begin
      child.FBareType := TgsJsonElementType.etEmpty;
      child.FBareValue := '';
    end;
  end;
end;

procedure AddArrayOfConst(const ARoot: TJsonValue; const vals: array of const);
var
  i: integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : ARoot.Add(JsonString(String(vals[i].VString^)));
      vtWideString    : ARoot.Add(JsonString(WideString(vals[i].VWideString)));
      vtUnicodeString : ARoot.Add(JsonString(UnicodeString(vals[i].VUnicodeString)));
      vtInteger       : ARoot.Add(Int32(vals[i].VInteger));
      System.vtBoolean: ARoot.Add(Boolean(vals[i].VBoolean));
      vtExtended      : ARoot.Add(Double(vals[i].VExtended^));
      vtInt64         : ARoot.Add(vals[i].VInt64^);
    end;
  end;
end;

{ TgsJsonImplNeslibJson }

constructor TgsJsonImplNeslibJson.Create;
begin
  FDoc := nil;
  FOwned := true;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
end;

destructor TgsJsonImplNeslibJson.Destroy;
begin
  FDoc := nil;
  inherited;
end;

procedure TgsJsonImplNeslibJson.EnsureDict;
begin
  if FBareType <> TgsJsonElementType.etEmpty then begin
    FBareType := TgsJsonElementType.etEmpty;
    FBareValue := '';
  end;
  if (FDoc = nil) or (not FDoc.Root.IsDictionary) then begin
    FDoc := TJsonDocument.CreateDictionary;
    FOwned := true;
  end;
end;

procedure TgsJsonImplNeslibJson.EnsureArray;
begin
  if FBareType <> TgsJsonElementType.etEmpty then begin
    FBareType := TgsJsonElementType.etEmpty;
    FBareValue := '';
  end;
  if (FDoc = nil) or (not FDoc.Root.IsArray) then begin
    FDoc := TJsonDocument.CreateArray;
    FOwned := true;
  end;
end;

function TgsJsonImplNeslibJson.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
  c : Char;
begin
  result := self;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';

  trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');

  c := trimmed[1];

  // Neslib.Json only supports objects and arrays as root.
  // Handle bare values manually.
  if (c = '{') or (c = '[') then begin
    FDoc := TJsonDocument.Parse(trimmed);
    if FDoc = nil then
      raise JsonException.Create('JSON parse error: ' + aJsonStr);
    FOwned := true;
  end
  else begin
    // Bare value
    FDoc := nil;
    FOwned := true;
    if trimmed = 'null' then begin
      FBareType := TgsJsonElementType.etNull;
      FBareValue := 'null';
    end
    else if (trimmed = 'true') or (trimmed = 'false') then begin
      FBareType := TgsJsonElementType.etBoolean;
      FBareValue := LowerCase(trimmed);
    end
    else if (c = '"') then begin
      FBareType := TgsJsonElementType.etString;
      // Remove surrounding quotes
      FBareValue := Copy(trimmed, 2, Length(trimmed) - 2);
    end
    else begin
      // Must be a number
      FBareType := TgsJsonElementType.etNumber;
      FBareValue := trimmed;
    end;
  end;
end;

function TgsJsonImplNeslibJson.put(name: string; val: double): igsJson;
begin
  result := self;
  EnsureDict;
  FDoc.Root.AddOrSetValue(name, val);
end;

function TgsJsonImplNeslibJson.put(name, val: string): igsJson;
begin
  result := self;
  EnsureDict;
  FDoc.Root.AddOrSetValue(name, JsonString(val));
end;

function TgsJsonImplNeslibJson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  EnsureDict;
  FDoc.Root.AddOrSetValue(name, val);
end;

function TgsJsonImplNeslibJson.put(vals: array of const): igsJson;
begin
  result := self;
  EnsureArray;
  AddArrayOfConst(FDoc.Root, vals);
end;

function TgsJsonImplNeslibJson.put(name: string; vals: array of const): igsJson;
var
  arr : TJsonValue;
begin
  result := self;
  EnsureDict;
  arr := FDoc.Root.AddOrSetArray(name);
  AddArrayOfConst(arr, vals);
end;

function TgsJsonImplNeslibJson.put(name: string; val: igsJson): igsJson;
var
  parsed : IJsonDocument;
  childJson : string;
begin
  result := self;
  EnsureDict;
  childJson := val.stringify;
  // Re-parse and merge: we parse the child then re-serialize to embed it.
  // Since Neslib doesn't allow transferring TJsonValue between documents,
  // we use a workaround: build a wrapper, parse, extract.
  parsed := TJsonDocument.Parse('{"__tmp":' + childJson + '}');
  if (parsed <> nil) then begin
    // We need to copy the value. The easiest way is to serialize the whole
    // current doc, add the key, and reparse. But that's expensive.
    // Instead, we'll serialize our current doc, modify the JSON string.
    // Actually, the simplest approach: serialize current + add at string level.
    // Better approach: just re-serialize the whole thing.
    var currentJson := FDoc.ToJson(False);
    // Remove trailing }
    if (Length(currentJson) > 0) and (currentJson[Length(currentJson)] = '}') then begin
      if FDoc.Root.Count > 0 then
        currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + ',"' + name + '":' + childJson + '}'
      else
        currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + '"' + name + '":' + childJson + '}';
      FDoc := TJsonDocument.Parse(currentJson);
    end;
  end;
end;

function TgsJsonImplNeslibJson.put(val: igsJson): igsJson;
var
  childJson, currentJson : string;
begin
  result := self;
  EnsureArray;
  childJson := val.stringify;
  // Same workaround: serialize, inject, re-parse
  currentJson := FDoc.ToJson(False);
  if (Length(currentJson) > 0) and (currentJson[Length(currentJson)] = ']') then begin
    if FDoc.Root.Count > 0 then
      currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + ',' + childJson + ']'
    else
      currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + childJson + ']';
    FDoc := TJsonDocument.Parse(currentJson);
  end;
end;

function TgsJsonImplNeslibJson.stringify(var aStr: string): igsJson;
begin
  result := self;
  aStr := stringify;
end;

function TgsJsonImplNeslibJson.stringify: string;
begin
  if FBareType <> TgsJsonElementType.etEmpty then begin
    case FBareType of
      TgsJsonElementType.etString : result := '"' + FBareValue + '"';
      TgsJsonElementType.etNull   : result := 'null';
    else
      result := FBareValue;
    end;
  end
  else if FDoc <> nil then
    result := FDoc.ToJson(False)
  else
    result := 'null';
end;

function TgsJsonImplNeslibJson.get(name: string; var value: string): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    if FDoc.Root.Contains(name) then begin
      v := FDoc.Root.Values[name];
      value := v.ToString;
    end
    else
      raise JsonException.Create('TgsJsonImplNeslibJson.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.get: Not an object');
end;

function TgsJsonImplNeslibJson.get(index: integer; var value: string): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Elements[index].Value;
    value := v.ToString;
  end
  else if (FDoc <> nil) and FDoc.Root.IsArray then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Items[index];
    value := v.ToString;
  end;
end;

function TgsJsonImplNeslibJson.get(name: string; var value: integer): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    v := FDoc.Root.Values[name];
    value := v.ToInteger;
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.get: Not an object');
end;

function TgsJsonImplNeslibJson.get(index: integer; var value: integer): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Elements[index].Value;
    value := v.ToInteger;
  end
  else if (FDoc <> nil) and FDoc.Root.IsArray then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Items[index];
    value := v.ToInteger;
  end;
end;

function TgsJsonImplNeslibJson.get(name: string; var value: Double): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    v := FDoc.Root.Values[name];
    value := v.ToDouble;
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.get: Not an object');
end;

function TgsJsonImplNeslibJson.get(index: integer; var value: Double): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Elements[index].Value;
    value := v.ToDouble;
  end
  else if (FDoc <> nil) and FDoc.Root.IsArray then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Items[index];
    value := v.ToDouble;
  end;
end;

function TgsJsonImplNeslibJson.get(name: string; var value: Boolean): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    v := FDoc.Root.Values[name];
    value := v.ToBoolean;
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.get: Not an object');
end;

function TgsJsonImplNeslibJson.get(index: integer; var value: Boolean): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Elements[index].Value;
    value := v.ToBoolean;
  end
  else if (FDoc <> nil) and FDoc.Root.IsArray then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Items[index];
    value := v.ToBoolean;
  end;
end;

function TgsJsonImplNeslibJson.get(name: string; var value: igsJson): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    if FDoc.Root.Contains(name) then begin
      v := FDoc.Root.Values[name];
      ExtractNeslibValue(FDoc, v, value);
    end
    else
      raise JsonException.Create('TgsJsonImplNeslibJson.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.get: Not an object');
end;

function TgsJsonImplNeslibJson.get(index: integer; var value: igsJson): igsJson;
var
  v : TJsonValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Elements[index].Value;
    ExtractNeslibValue(FDoc, v, value);
  end
  else if (FDoc <> nil) and FDoc.Root.IsArray then begin
    assert(index < FDoc.Root.Count);
    v := FDoc.Root.Items[index];
    ExtractNeslibValue(FDoc, v, value);
  end;
end;

function TgsJsonImplNeslibJson.jsonElementCount: integer;
begin
  if (FDoc <> nil) then begin
    if FDoc.Root.IsDictionary or FDoc.Root.IsArray then
      result := FDoc.Root.Count
    else
      result := -1;
  end
  else
    result := -1;
end;

function TgsJsonImplNeslibJson.jsonElementType(index: integer): TgsJsonElementType;
var
  v : TJsonValue;
begin
  result := TgsJsonElementType.etEmpty;
  if FDoc <> nil then begin
    if FDoc.Root.IsDictionary then begin
      if (index >= 0) and (index < FDoc.Root.Count) then begin
        v := FDoc.Root.Elements[index].Value;
        result := NeslibValueToElementType(v);
      end;
    end
    else if FDoc.Root.IsArray then begin
      if (index >= 0) and (index < FDoc.Root.Count) then begin
        v := FDoc.Root.Items[index];
        result := NeslibValueToElementType(v);
      end;
    end;
  end;
end;

function TgsJsonImplNeslibJson.jsonType: TgsJsonElementType;
begin
  if FBareType <> TgsJsonElementType.etEmpty then
    result := FBareType
  else if FDoc <> nil then
    result := NeslibValueToElementType(FDoc.Root)
  else
    result := TgsJsonElementType.etEmpty;
end;

function TgsJsonImplNeslibJson.jsonElementName(index: integer): string;
var
  elem : PJsonElement;
begin
  result := '';
  if (FDoc <> nil) and FDoc.Root.IsDictionary then begin
    assert(index < FDoc.Root.Count);
    elem := FDoc.Root.Elements[index];
    if elem <> nil then
      result := elem.Name;
  end
  else
    raise JsonException.Create('TgsJsonImplNeslibJson.jsonElementName: Not an object');
end;

function TgsJsonImplNeslibJson.clear: igsJson;
begin
  result := self;
  FDoc := nil;
  FOwned := true;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
end;

function TgsJsonImplNeslibJson.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplNeslibJson.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplNeslibJson.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplNeslibJson.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplNeslibJson.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplNeslibJson.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplNeslibJson.add(val: igsJson): igsJson;
var
  childJson, currentJson : string;
begin
  result := self;
  EnsureArray;
  childJson := val.stringify;
  currentJson := FDoc.ToJson(False);
  if (Length(currentJson) > 0) and (currentJson[Length(currentJson)] = ']') then begin
    if FDoc.Root.Count > 0 then
      currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + ',' + childJson + ']'
    else
      currentJson := Copy(currentJson, 1, Length(currentJson) - 1) + childJson + ']';
    FDoc := TJsonDocument.Parse(currentJson);
  end;
end;

function TgsJsonImplNeslibJson.add(val: double): igsJson;
begin
  result := self;
  EnsureArray;
  FDoc.Root.Add(val);
end;

function TgsJsonImplNeslibJson.add(val: integer): igsJson;
begin
  result := self;
  EnsureArray;
  FDoc.Root.Add(Int32(val));
end;

function TgsJsonImplNeslibJson.add(val: string): igsJson;
begin
  result := self;
  EnsureArray;
  FDoc.Root.Add(JsonString(val));
end;

function TgsJsonImplNeslibJson.add(val: byte): igsJson;
begin
  result := self;
  EnsureArray;
  FDoc.Root.Add(Int32(val));
end;

function TgsJsonImplNeslibJson.add(val: boolean): igsJson;
begin
  result := self;
  EnsureArray;
  FDoc.Root.Add(val);
end;

function TgsJsonImplNeslibJson.isNameExists(name: String): boolean;
begin
  result := false;
  if (FDoc <> nil) and FDoc.Root.IsDictionary then
    result := FDoc.Root.Contains(name);
end;

function TgsJsonImplNeslibJson.ToObj: igsJson;
begin
  result := self;
  EnsureDict;
end;

function TgsJsonImplNeslibJson.ToArray: igsJson;
begin
  result := self;
  EnsureArray;
end;

{ TgsJsonImplNeslibJsonFactory }

function TgsJsonImplNeslibJsonFactory.getAuthor: string;
begin
  result := 'Erik van Bilsen';
end;

function TgsJsonImplNeslibJsonFactory.getTitle: string;
begin
  result := 'Neslib.Json';
end;

function TgsJsonImplNeslibJsonFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplNeslibJsonFactory.getId: string;
begin
  result := 'neslibjson';
end;

function TgsJsonImplNeslibJsonFactory.getJson: igsJson;
begin
  result := TgsJsonImplNeslibJson.Create;
end;

initialization

addImplementation(TgsJsonImplNeslibJsonFactory.Create);

end.
