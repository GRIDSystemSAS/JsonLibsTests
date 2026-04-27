///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.jsonTools;

interface

uses sysutils,
     classes,
     gs.Json,
     JsonTools;

type

TgsJsonImplJsonTools = class(TInterfacedObject, igsJson)
private
protected
  FJson : TJsonNode;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

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

  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

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

TgsJsonImplJsonToolsFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

function nodeKindToElementType(aNode : TJsonNode) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aNode = nil then
    exit;
  case aNode.Kind of
    nkNull : result := TgsJsonElementType.etEmpty;
    nkBool : result := TgsJsonElementType.etBoolean;
    nkNumber : result := TgsJsonElementType.etNumber;
    nkString : result := TgsJsonElementType.etString;
    nkObject : result := TgsJsonElementType.etJson;
    nkArray : result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : TJsonNode; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplJsonTools.Create;

  if TgsJsonImplJsonTools(value).FOwned and (TgsJsonImplJsonTools(value).FJson <> nil) then
    TgsJsonImplJsonTools(value).FJson.Free;
  TgsJsonImplJsonTools(value).FJson := source;
  TgsJsonImplJsonTools(value).FOwned := false;
end;

procedure addValsToNode(node : TJsonNode; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : node.Add.AsString := String(vals[i].VString^);
      vtWideString : node.Add.AsString := String(vals[i].VWideString);
      vtUnicodeString : node.Add.AsString := UnicodeString(vals[i].VUnicodeString);
      vtInteger : node.Add.AsNumber := vals[i].VInteger;
      vtBoolean : node.Add.AsBoolean := vals[i].VBoolean;
      vtExtended : node.Add.AsNumber := vals[i].VExtended^;
    end;
  end;
end;

{ TgsJsonImplJsonTools }

constructor TgsJsonImplJsonTools.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplJsonTools.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplJsonTools.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then begin
    FJson.Free;
    FJson := nil;
  end;
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TJsonNode.Create;
  FOwned := true;
  FJson.Parse(trimmed); // raises EJsonException if invalid or if root is not object/array
end;

function TgsJsonImplJsonTools.put(name: string; val: double): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  FJson.Add(name, val);
end;

function TgsJsonImplJsonTools.put(name, val: string): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  FJson.Add(name, val);
end;

function TgsJsonImplJsonTools.put(name: string; val: boolean): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  FJson.Add(name, val);
end;

function TgsJsonImplJsonTools.put(vals: array of const): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  if FJson.Kind <> nkArray then
    FJson.Kind := nkArray;
  addValsToNode(FJson, vals);
end;

function TgsJsonImplJsonTools.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  var arr := FJson.Add(name, nkArray);
  addValsToNode(arr, vals);
end;

function TgsJsonImplJsonTools.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  var child := FJson.Add(name, nkObject);
  child.Parse(val.stringify);
end;

function TgsJsonImplJsonTools.put(val: igsJson): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  if FJson.Kind <> nkArray then
    FJson.Kind := nkArray;
  var child := FJson.Add;
  child.Parse(val.stringify);
end;

function TgsJsonImplJsonTools.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := FJson.AsJson
  else
    aStr := 'null';
end;

function TgsJsonImplJsonTools.stringify: string;
begin
  if FJson <> nil then
    result := FJson.AsJson
  else
    result := 'null';
end;

function TgsJsonImplJsonTools.get(name: string; var value: string): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    var child := FJson.Child(name);
    if child <> nil then
      value := child.AsString
    else
      raise Exception.Create('TgsJsonImplJsonTools.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplJsonTools.get: Not an object');
end;

function TgsJsonImplJsonTools.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson <> nil then begin
    assert(index < FJson.Count);
    value := FJson.Child(index).AsString;
  end;
end;

function TgsJsonImplJsonTools.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    var child := FJson.Child(name);
    if child <> nil then
      value := Round(child.AsNumber)
    else
      raise Exception.Create('TgsJsonImplJsonTools.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplJsonTools.get: Not an object');
end;

function TgsJsonImplJsonTools.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson <> nil then begin
    assert(index < FJson.Count);
    value := Round(FJson.Child(index).AsNumber);
  end;
end;

function TgsJsonImplJsonTools.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    var child := FJson.Child(name);
    if child <> nil then
      value := child.AsNumber
    else
      raise Exception.Create('TgsJsonImplJsonTools.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplJsonTools.get: Not an object');
end;

function TgsJsonImplJsonTools.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson <> nil then begin
    assert(index < FJson.Count);
    value := FJson.Child(index).AsNumber;
  end;
end;

function TgsJsonImplJsonTools.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    var child := FJson.Child(name);
    if child <> nil then
      value := child.AsBoolean
    else
      raise Exception.Create('TgsJsonImplJsonTools.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplJsonTools.get: Not an object');
end;

function TgsJsonImplJsonTools.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson <> nil then begin
    assert(index < FJson.Count);
    value := FJson.Child(index).AsBoolean;
  end;
end;

function TgsJsonImplJsonTools.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    var child := FJson.Child(name);
    if child <> nil then
      extractValue(child, value)
    else
      raise Exception.Create('TgsJsonImplJsonTools.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplJsonTools.get: Not an object');
end;

function TgsJsonImplJsonTools.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson <> nil then begin
    assert(index < FJson.Count);
    extractValue(FJson.Child(index), value);
  end;
end;

function TgsJsonImplJsonTools.jsonElementCount: integer;
begin
  if (FJson <> nil) and (FJson.Kind in [nkObject, nkArray]) then
    result := FJson.Count
  else
    result := -1;
end;

function TgsJsonImplJsonTools.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if (FJson <> nil) and (FJson.Kind in [nkObject, nkArray]) then
    result := nodeKindToElementType(FJson.Child(index));
end;

function TgsJsonImplJsonTools.jsonType: TgsJsonElementType;
begin
  result := nodeKindToElementType(FJson);
end;

function TgsJsonImplJsonTools.jsonElementName(index: integer): string;
begin
  result := '';
  if (FJson <> nil) and (FJson.Kind = nkObject) then begin
    assert(index < FJson.Count);
    result := FJson.Child(index).Name;
  end;
end;

function TgsJsonImplJsonTools.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplJsonTools.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplJsonTools.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplJsonTools.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplJsonTools.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplJsonTools.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplJsonTools.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplJsonTools.add(val: igsJson): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  if FJson.Kind <> nkArray then
    FJson.Kind := nkArray;
  var child := FJson.Add;
  child.Parse(val.stringify);
end;

function TgsJsonImplJsonTools.add(val: double): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
    FJson.Kind := nkArray;
  end;
  FJson.Add.AsNumber := val;
end;

function TgsJsonImplJsonTools.add(val: integer): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
    FJson.Kind := nkArray;
  end;
  FJson.Add.AsNumber := val;
end;

function TgsJsonImplJsonTools.add(val: string): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
    FJson.Kind := nkArray;
  end;
  FJson.Add.AsString := val;
end;

function TgsJsonImplJsonTools.add(val: byte): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
    FJson.Kind := nkArray;
  end;
  FJson.Add.AsNumber := Integer(val);
end;

function TgsJsonImplJsonTools.add(val: boolean): igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
    FJson.Kind := nkArray;
  end;
  FJson.Add.AsBoolean := val;
end;

function TgsJsonImplJsonTools.isNameExists(name: String): boolean;
begin
  result := false;
  if (FJson <> nil) and (FJson.Kind = nkObject) then
    result := FJson.Child(name) <> nil;
end;

function TgsJsonImplJsonTools.ToObj: igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  if FJson.Kind <> nkObject then
    FJson.Kind := nkObject;
end;

function TgsJsonImplJsonTools.ToArray: igsJson;
begin
  result := self;
  if FJson = nil then begin
    FJson := TJsonNode.Create;
    FOwned := true;
  end;
  if FJson.Kind <> nkArray then
    FJson.Kind := nkArray;
end;

{ TgsJsonImplJsonToolsFactory }

function TgsJsonImplJsonToolsFactory.getAuthor: string;
begin
  result := 'sysrpl (GetLazarus.org)';
end;

function TgsJsonImplJsonToolsFactory.getTitle: string;
begin
  result := 'JsonTools';
end;

function TgsJsonImplJsonToolsFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplJsonToolsFactory.getId: string;
begin
  result := 'jsontools';
end;

function TgsJsonImplJsonToolsFactory.getJson: igsJson;
begin
  result := TgsJsonImplJsonTools.Create;
end;

initialization

addImplementation(TgsJsonImplJsonToolsFactory.Create);

end.
