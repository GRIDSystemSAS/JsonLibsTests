///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.grijjyBson;

interface

uses sysutils,
     classes,
     gs.Json,
     Grijjy.Bson;

type

TgsJsonImplGrijjyBson = class(TInterfacedObject, igsJson)
private
protected
  FDoc : TgoBsonDocument;
  FArr : TgoBsonArray;
  FIsArray : boolean;
  FOwned : boolean;
  // Bare value support
  FBareValue : string;
  FBareType  : TgsJsonElementType;
  procedure EnsureDoc;
  procedure EnsureArr;
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

TgsJsonImplGrijjyBsonFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

{ Helpers }

function BsonTypeToElementType(ABsonType: TgoBsonType): TgsJsonElementType;
begin
  case ABsonType of
    TgoBsonType.Null       : result := TgsJsonElementType.etNull;
    TgoBsonType.Boolean    : result := TgsJsonElementType.etBoolean;
    TgoBsonType.Double,
    TgoBsonType.Int32,
    TgoBsonType.Int64      : result := TgsJsonElementType.etNumber;
    TgoBsonType.&String    : result := TgsJsonElementType.etString;
    TgoBsonType.Document   : result := TgsJsonElementType.etJson;
    TgoBsonType.&Array     : result := TgsJsonElementType.etJsonArray;
  else
    result := TgsJsonElementType.etEmpty;
  end;
end;

procedure ExtractBsonValue(const AValue: TgoBsonValue; var value: igsJson);
var
  child : TgsJsonImplGrijjyBson;
begin
  if not assigned(value) then
    value := TgsJsonImplGrijjyBson.Create;
  child := TgsJsonImplGrijjyBson(value);
  child.FBareType := TgsJsonElementType.etEmpty;
  child.FBareValue := '';
  child.FOwned := true;

  if AValue.IsBsonDocument then begin
    child.FDoc := AValue.AsBsonDocument;
    child.FIsArray := false;
  end
  else if AValue.IsBsonArray then begin
    child.FArr := AValue.AsBsonArray;
    child.FIsArray := true;
  end
  else begin
    // Bare value
    if AValue.IsNil then begin
      child.FBareType := TgsJsonElementType.etNull;
      child.FBareValue := 'null';
    end
    else if AValue.BsonType = TgoBsonType.Boolean then begin
      child.FBareType := TgsJsonElementType.etBoolean;
      if AValue.AsBoolean then
        child.FBareValue := 'true'
      else
        child.FBareValue := 'false';
    end
    else if AValue.BsonType = TgoBsonType.&String then begin
      child.FBareType := TgsJsonElementType.etString;
      child.FBareValue := AValue.AsString;
    end
    else begin
      child.FBareType := TgsJsonElementType.etNumber;
      child.FBareValue := AValue.ToJson;
    end;
  end;
end;

procedure AddArrayOfConst(var AArr: TgoBsonArray; const vals: array of const);
var
  i: integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString        : AArr.Add(TgoBsonValue(String(vals[i].VString^)));
      vtWideString    : AArr.Add(TgoBsonValue(String(WideString(vals[i].VWideString))));
      vtUnicodeString : AArr.Add(TgoBsonValue(String(UnicodeString(vals[i].VUnicodeString))));
      vtInteger       : AArr.Add(TgoBsonValue(Int32(vals[i].VInteger)));
      System.vtBoolean: AArr.Add(TgoBsonValue(Boolean(vals[i].VBoolean)));
      vtExtended      : AArr.Add(TgoBsonValue(Double(vals[i].VExtended^)));
      vtInt64         : AArr.Add(TgoBsonValue(vals[i].VInt64^));
    end;
  end;
end;

{ TgsJsonImplGrijjyBson }

constructor TgsJsonImplGrijjyBson.Create;
begin
  FIsArray := false;
  FOwned := true;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
end;

destructor TgsJsonImplGrijjyBson.Destroy;
begin
  inherited;
end;

procedure TgsJsonImplGrijjyBson.EnsureDoc;
begin
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  if FIsArray or FDoc.IsNil then begin
    FDoc := TgoBsonDocument.Create;
    FIsArray := false;
    FOwned := true;
  end;
end;

procedure TgsJsonImplGrijjyBson.EnsureArr;
begin
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
  if (not FIsArray) or FArr.IsNil then begin
    FArr := TgoBsonArray.Create;
    FIsArray := true;
    FOwned := true;
  end;
end;

function TgsJsonImplGrijjyBson.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
  c : char;
  v : TgoBsonValue;
begin
  result := self;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';

  trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');

  c := trimmed[1];

  if c = '{' then begin
    FDoc := TgoBsonDocument.Parse(trimmed);
    FIsArray := false;
  end
  else if c = '[' then begin
    FArr := TgoBsonArray.Parse(trimmed);
    FIsArray := true;
  end
  else begin
    // Bare value - try parsing as generic BsonValue
    v := TgoBsonValue.Parse(trimmed);
    if v.IsNil then begin
      // manual bare value
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
        FBareValue := Copy(trimmed, 2, Length(trimmed) - 2);
      end
      else begin
        FBareType := TgsJsonElementType.etNumber;
        FBareValue := trimmed;
      end;
    end
    else begin
      var intf: igsJson := self;
      ExtractBsonValue(v, intf);
    end;
  end;
end;

function TgsJsonImplGrijjyBson.put(name: string; val: double): igsJson;
begin
  result := self;
  EnsureDoc;
  if FDoc.Contains(name) then
    FDoc[name] := val
  else
    FDoc.Add(name, val);
end;

function TgsJsonImplGrijjyBson.put(name, val: string): igsJson;
begin
  result := self;
  EnsureDoc;
  if FDoc.Contains(name) then
    FDoc[name] := val
  else
    FDoc.Add(name, val);
end;

function TgsJsonImplGrijjyBson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  EnsureDoc;
  if FDoc.Contains(name) then
    FDoc[name] := val
  else
    FDoc.Add(name, val);
end;

function TgsJsonImplGrijjyBson.put(vals: array of const): igsJson;
begin
  result := self;
  EnsureArr;
  AddArrayOfConst(FArr, vals);
end;

function TgsJsonImplGrijjyBson.put(name: string; vals: array of const): igsJson;
var
  arr : TgoBsonArray;
begin
  result := self;
  EnsureDoc;
  arr := TgoBsonArray.Create;
  AddArrayOfConst(arr, vals);
  if FDoc.Contains(name) then
    FDoc[name] := arr
  else
    FDoc.Add(name, arr);
end;

function TgsJsonImplGrijjyBson.put(name: string; val: igsJson): igsJson;
var
  childJson : string;
  childDoc : TgoBsonDocument;
  childArr : TgoBsonArray;
  c : char;
begin
  result := self;
  EnsureDoc;
  childJson := val.stringify;
  if (Length(childJson) > 0) then begin
    c := childJson[1];
    if c = '{' then begin
      childDoc := TgoBsonDocument.Parse(childJson);
      if FDoc.Contains(name) then
        FDoc[name] := childDoc
      else
        FDoc.Add(name, childDoc);
    end
    else if c = '[' then begin
      childArr := TgoBsonArray.Parse(childJson);
      if FDoc.Contains(name) then
        FDoc[name] := childArr
      else
        FDoc.Add(name, childArr);
    end
    else begin
      if FDoc.Contains(name) then
        FDoc[name] := childJson
      else
        FDoc.Add(name, childJson);
    end;
  end;
end;

function TgsJsonImplGrijjyBson.put(val: igsJson): igsJson;
var
  childJson : string;
  childDoc : TgoBsonDocument;
  childArr : TgoBsonArray;
  c : char;
begin
  result := self;
  EnsureArr;
  childJson := val.stringify;
  if (Length(childJson) > 0) then begin
    c := childJson[1];
    if c = '{' then begin
      childDoc := TgoBsonDocument.Parse(childJson);
      FArr.Add(childDoc);
    end
    else if c = '[' then begin
      childArr := TgoBsonArray.Parse(childJson);
      FArr.Add(childArr);
    end
    else
      FArr.Add(TgoBsonValue(childJson));
  end;
end;

function TgsJsonImplGrijjyBson.stringify(var aStr: string): igsJson;
begin
  result := self;
  aStr := stringify;
end;

function TgsJsonImplGrijjyBson.stringify: string;
begin
  if FBareType <> TgsJsonElementType.etEmpty then begin
    case FBareType of
      TgsJsonElementType.etString : result := '"' + FBareValue + '"';
      TgsJsonElementType.etNull   : result := 'null';
    else
      result := FBareValue;
    end;
  end
  else if FIsArray then
    result := FArr.ToJson
  else
    result := FDoc.ToJson;
end;

function TgsJsonImplGrijjyBson.get(name: string; var value: string): igsJson;
begin
  result := self;
  if (not FIsArray) and (FDoc._Impl <> nil) then
    value := string(FDoc[name])
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.get: Not an object');
end;

function TgsJsonImplGrijjyBson.get(index: integer; var value: string): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if FIsArray then begin
    v := FArr[index];
    value := string(v);
  end
  else if FDoc._Impl <> nil then begin
    v := FDoc.Values[index];
    value := string(v);
  end;
end;

function TgsJsonImplGrijjyBson.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if (not FIsArray) and (FDoc._Impl <> nil) then
    value := Integer(Int32(FDoc[name]))
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.get: Not an object');
end;

function TgsJsonImplGrijjyBson.get(index: integer; var value: integer): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if FIsArray then begin
    v := FArr[index];
    value := Integer(Int32(v));
  end
  else if FDoc._Impl <> nil then begin
    v := FDoc.Values[index];
    value := Integer(Int32(v));
  end;
end;

function TgsJsonImplGrijjyBson.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if (not FIsArray) and (FDoc._Impl <> nil) then
    value := Double(FDoc[name])
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.get: Not an object');
end;

function TgsJsonImplGrijjyBson.get(index: integer; var value: Double): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if FIsArray then begin
    v := FArr[index];
    value := Double(v);
  end
  else if FDoc._Impl <> nil then begin
    v := FDoc.Values[index];
    value := Double(v);
  end;
end;

function TgsJsonImplGrijjyBson.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if (not FIsArray) and (FDoc._Impl <> nil) then
    value := Boolean(FDoc[name])
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.get: Not an object');
end;

function TgsJsonImplGrijjyBson.get(index: integer; var value: Boolean): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if FIsArray then begin
    v := FArr[index];
    value := Boolean(v);
  end
  else if FDoc._Impl <> nil then begin
    v := FDoc.Values[index];
    value := Boolean(v);
  end;
end;

function TgsJsonImplGrijjyBson.get(name: string; var value: igsJson): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if (not FIsArray) and (FDoc._Impl <> nil) then begin
    v := FDoc[name];
    ExtractBsonValue(v, value);
  end
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.get: Not an object');
end;

function TgsJsonImplGrijjyBson.get(index: integer; var value: igsJson): igsJson;
var
  v : TgoBsonValue;
begin
  result := self;
  if FIsArray then begin
    v := FArr[index];
    ExtractBsonValue(v, value);
  end
  else if FDoc._Impl <> nil then begin
    v := FDoc.Values[index];
    ExtractBsonValue(v, value);
  end;
end;

function TgsJsonImplGrijjyBson.jsonElementCount: integer;
begin
  if FBareType <> TgsJsonElementType.etEmpty then
    result := -1
  else if FIsArray then
    result := FArr.Count
  else if FDoc._Impl <> nil then
    result := FDoc.Count
  else
    result := -1;
end;

function TgsJsonImplGrijjyBson.jsonElementType(index: integer): TgsJsonElementType;
var
  v : TgoBsonValue;
begin
  result := TgsJsonElementType.etEmpty;
  if FIsArray then begin
    if (index >= 0) and (index < FArr.Count) then begin
      v := FArr[index];
      result := BsonTypeToElementType(v.BsonType);
    end;
  end
  else if FDoc._Impl <> nil then begin
    if (index >= 0) and (index < FDoc.Count) then begin
      v := FDoc.Values[index];
      result := BsonTypeToElementType(v.BsonType);
    end;
  end;
end;

function TgsJsonImplGrijjyBson.jsonType: TgsJsonElementType;
begin
  if FBareType <> TgsJsonElementType.etEmpty then
    result := FBareType
  else if FIsArray then
    result := TgsJsonElementType.etJsonArray
  else if FDoc._Impl <> nil then
    result := TgsJsonElementType.etJson
  else
    result := TgsJsonElementType.etEmpty;
end;

function TgsJsonImplGrijjyBson.jsonElementName(index: integer): string;
begin
  result := '';
  if (not FIsArray) and (FDoc._Impl <> nil) then begin
    assert(index < FDoc.Count);
    result := FDoc.Elements[index].Name;
  end
  else
    raise Exception.Create('TgsJsonImplGrijjyBson.jsonElementName: Not an object');
end;

function TgsJsonImplGrijjyBson.clear: igsJson;
begin
  result := self;
  FDoc := TgoBsonDocument.Create;
  FIsArray := false;
  FOwned := true;
  FBareType := TgsJsonElementType.etEmpty;
  FBareValue := '';
end;

function TgsJsonImplGrijjyBson.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplGrijjyBson.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplGrijjyBson.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplGrijjyBson.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplGrijjyBson.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplGrijjyBson.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplGrijjyBson.add(val: igsJson): igsJson;
var
  childJson : string;
  c : char;
begin
  result := self;
  EnsureArr;
  childJson := val.stringify;
  if (Length(childJson) > 0) then begin
    c := childJson[1];
    if c = '{' then
      FArr.Add(TgoBsonDocument.Parse(childJson))
    else if c = '[' then
      FArr.Add(TgoBsonArray.Parse(childJson))
    else
      FArr.Add(TgoBsonValue(childJson));
  end;
end;

function TgsJsonImplGrijjyBson.add(val: double): igsJson;
begin
  result := self;
  EnsureArr;
  FArr.Add(val);
end;

function TgsJsonImplGrijjyBson.add(val: integer): igsJson;
begin
  result := self;
  EnsureArr;
  FArr.Add(Int32(val));
end;

function TgsJsonImplGrijjyBson.add(val: string): igsJson;
begin
  result := self;
  EnsureArr;
  FArr.Add(TgoBsonValue(val));
end;

function TgsJsonImplGrijjyBson.add(val: byte): igsJson;
begin
  result := self;
  EnsureArr;
  FArr.Add(Int32(val));
end;

function TgsJsonImplGrijjyBson.add(val: boolean): igsJson;
begin
  result := self;
  EnsureArr;
  FArr.Add(val);
end;

function TgsJsonImplGrijjyBson.isNameExists(name: String): boolean;
begin
  result := false;
  if (not FIsArray) and (FDoc._Impl <> nil) then
    result := FDoc.Contains(name);
end;

function TgsJsonImplGrijjyBson.ToObj: igsJson;
begin
  result := self;
  EnsureDoc;
end;

function TgsJsonImplGrijjyBson.ToArray: igsJson;
begin
  result := self;
  EnsureArr;
end;

{ TgsJsonImplGrijjyBsonFactory }

function TgsJsonImplGrijjyBsonFactory.getAuthor: string;
begin
  result := 'Grijjy';
end;

function TgsJsonImplGrijjyBsonFactory.getTitle: string;
begin
  result := 'Grijjy.Bson';
end;

function TgsJsonImplGrijjyBsonFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplGrijjyBsonFactory.getId: string;
begin
  result := 'grijjybson';
end;

function TgsJsonImplGrijjyBsonFactory.getJson: igsJson;
begin
  result := TgsJsonImplGrijjyBson.Create;
end;

initialization

addImplementation(TgsJsonImplGrijjyBsonFactory.Create);

end.
