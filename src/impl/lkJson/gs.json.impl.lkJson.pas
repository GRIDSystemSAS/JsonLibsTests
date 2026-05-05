///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.lkJson;

interface

uses sysutils,
     classes,
     gs.Json,
     uLkJSON;

type

TgsJsonImplLk = class(TInterfacedObject, igsJson)
private
protected
  FJson : TlkJSONbase;
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

TgsJsonImplLkFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

uses Variants;

function lkTypeToElementType(aItem : TlkJSONbase) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aItem = nil then
    exit;
  case aItem.SelfType of
    jsNull : result := TgsJsonElementType.etEmpty;
    jsBoolean : result := TgsJsonElementType.etBoolean;
    jsNumber : result := TgsJsonElementType.etNumber;
    jsString : result := TgsJsonElementType.etString;
    jsObject : result := TgsJsonElementType.etJson;
    jsList : result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : TlkJSONbase; var value : igsJson);
begin
  if not assigned(value) then
    value := TgsJsonImplLk.Create;

  if TgsJsonImplLk(value).FOwned and (TgsJsonImplLk(value).FJson <> nil) then
    TgsJsonImplLk(value).FJson.Free;
  TgsJsonImplLk(value).FJson := source;
  TgsJsonImplLk(value).FOwned := false;
end;

function getAsObj(var FJson : TlkJSONbase; var FOwned : boolean) : TlkJSONobject;
begin
  if not (FJson is TlkJSONobject) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TlkJSONobject.Generate;
    FOwned := true;
  end;
  result := TlkJSONobject(FJson);
end;

function getAsList(var FJson : TlkJSONbase; var FOwned : boolean) : TlkJSONlist;
begin
  if not (FJson is TlkJSONlist) then begin
    if FOwned and (FJson <> nil) then
      FJson.Free;
    FJson := TlkJSONlist.Generate;
    FOwned := true;
  end;
  result := TlkJSONlist(FJson);
end;

procedure addToList(lst : TlkJSONlist; const vals : array of const);
begin
  for var i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : lst.Add(String(vals[i].VString^));
      vtWideString : lst.Add(WideString(vals[i].VWideString));
      vtUnicodeString : lst.Add(WideString(UnicodeString(vals[i].VUnicodeString)));
      vtInteger : lst.Add(vals[i].VInteger);
      vtBoolean : lst.Add(vals[i].VBoolean);
      vtExtended : lst.Add(Double(vals[i].VExtended^));
    end;
  end;
end;

{ TgsJsonImplLk }

constructor TgsJsonImplLk.Create;
begin
  FJson := nil;
  FOwned := true;
end;

destructor TgsJsonImplLk.Destroy;
begin
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJsonImplLk.parse(aJsonStr: string): igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  var trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FJson := TlkJSON.ParseText(trimmed);
  if FJson = nil then
    raise JsonException.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

function TgsJsonImplLk.put(name: string; val: double): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var idx := obj.IndexOfName(name);
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(name, val);
end;

function TgsJsonImplLk.put(name, val: string): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var idx := obj.IndexOfName(name);
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(name, val);
end;

function TgsJsonImplLk.put(name: string; val: boolean): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var idx := obj.IndexOfName(name);
  if idx >= 0 then
    obj.Delete(idx);
  obj.Add(name, val);
end;

function TgsJsonImplLk.put(vals: array of const): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  addToList(lst, vals);
end;

function TgsJsonImplLk.put(name: string; vals: array of const): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var idx := obj.IndexOfName(name);
  if idx >= 0 then
    obj.Delete(idx);
  var lst := TlkJSONlist.Generate;
  addToList(lst, vals);
  obj.Add(name, lst);
end;

function TgsJsonImplLk.put(name: string; val: igsJson): igsJson;
begin
  result := self;
  var obj := getAsObj(FJson, FOwned);
  var idx := obj.IndexOfName(name);
  if idx >= 0 then
    obj.Delete(idx);
  var parsed := TlkJSON.ParseText(val.stringify);
  if parsed <> nil then
    obj.Add(name, parsed);
end;

function TgsJsonImplLk.put(val: igsJson): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  var parsed := TlkJSON.ParseText(val.stringify);
  if parsed <> nil then
    lst.Add(parsed);
end;

function TgsJsonImplLk.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FJson <> nil then
    aStr := TlkJSON.GenerateText(FJson)
  else
    aStr := 'null';
end;

function TgsJsonImplLk.stringify: string;
begin
  if FJson <> nil then
    result := TlkJSON.GenerateText(FJson)
  else
    result := 'null';
end;

function TgsJsonImplLk.get(name: string; var value: string): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    var v := TlkJSONobject(FJson).Field[name];
    if v <> nil then
      value := VarToStr(v.Value)
    else
      raise Exception.Create('TgsJsonImplLk.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplLk.get: Not an object');
end;

function TgsJsonImplLk.get(index: integer; var value: string): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    value := VarToStr(TlkJSONobject(FJson).FieldByIndex[index].Value);
  end
  else if FJson is TlkJSONlist then begin
    assert(index < TlkJSONlist(FJson).Count);
    value := VarToStr(TlkJSONlist(FJson).Child[index].Value);
  end;
end;

function TgsJsonImplLk.get(name: string; var value: integer): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    var v := TlkJSONobject(FJson).Field[name];
    if v <> nil then
      value := v.Value
    else
      raise Exception.Create('TgsJsonImplLk.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplLk.get: Not an object');
end;

function TgsJsonImplLk.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    value := TlkJSONobject(FJson).FieldByIndex[index].Value;
  end
  else if FJson is TlkJSONlist then begin
    assert(index < TlkJSONlist(FJson).Count);
    value := TlkJSONlist(FJson).Child[index].Value;
  end;
end;

function TgsJsonImplLk.get(name: string; var value: Double): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    var v := TlkJSONobject(FJson).Field[name];
    if v <> nil then
      value := v.Value
    else
      raise Exception.Create('TgsJsonImplLk.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplLk.get: Not an object');
end;

function TgsJsonImplLk.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    value := TlkJSONobject(FJson).FieldByIndex[index].Value;
  end
  else if FJson is TlkJSONlist then begin
    assert(index < TlkJSONlist(FJson).Count);
    value := TlkJSONlist(FJson).Child[index].Value;
  end;
end;

function TgsJsonImplLk.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    var v := TlkJSONobject(FJson).Field[name];
    if v <> nil then
      value := v.Value
    else
      raise Exception.Create('TgsJsonImplLk.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplLk.get: Not an object');
end;

function TgsJsonImplLk.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    value := TlkJSONobject(FJson).FieldByIndex[index].Value;
  end
  else if FJson is TlkJSONlist then begin
    assert(index < TlkJSONlist(FJson).Count);
    value := TlkJSONlist(FJson).Child[index].Value;
  end;
end;

function TgsJsonImplLk.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    var v := TlkJSONobject(FJson).Field[name];
    if v <> nil then
      extractValue(v, value)
    else
      raise Exception.Create('TgsJsonImplLk.get: Key not found: ' + name);
  end
  else
    raise Exception.Create('TgsJsonImplLk.get: Not an object');
end;

function TgsJsonImplLk.get(index: integer; var value: igsJson): igsJson;
begin
  result := self;
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    extractValue(TlkJSONobject(FJson).FieldByIndex[index], value);
  end
  else if FJson is TlkJSONlist then begin
    assert(index < TlkJSONlist(FJson).Count);
    extractValue(TlkJSONlist(FJson).Child[index], value);
  end;
end;

function TgsJsonImplLk.jsonElementCount: integer;
begin
  if FJson is TlkJSONobject then
    result := TlkJSONobject(FJson).Count
  else if FJson is TlkJSONlist then
    result := TlkJSONlist(FJson).Count
  else
    result := -1;
end;

function TgsJsonImplLk.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FJson is TlkJSONobject then
    result := lkTypeToElementType(TlkJSONobject(FJson).FieldByIndex[index])
  else if FJson is TlkJSONlist then
    result := lkTypeToElementType(TlkJSONlist(FJson).Child[index]);
end;

function TgsJsonImplLk.jsonType: TgsJsonElementType;
begin
  result := lkTypeToElementType(FJson);
end;

function TgsJsonImplLk.jsonElementName(index: integer): string;
begin
  result := '';
  if FJson is TlkJSONobject then begin
    assert(index < TlkJSONobject(FJson).Count);
    result := TlkJSONobject(FJson).NameOf[index];
  end;
end;

function TgsJsonImplLk.clear: igsJson;
begin
  result := self;
  if FOwned and (FJson <> nil) then
    FreeAndNil(FJson);
  FJson := nil;
  FOwned := true;
end;

function TgsJsonImplLk.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplLk.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplLk.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplLk.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplLk.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplLk.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

function TgsJsonImplLk.add(val: igsJson): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  var parsed := TlkJSON.ParseText(val.stringify);
  if parsed <> nil then
    lst.Add(parsed);
end;

function TgsJsonImplLk.add(val: double): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  lst.Add(val);
end;

function TgsJsonImplLk.add(val: integer): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  lst.Add(val);
end;

function TgsJsonImplLk.add(val: string): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  lst.Add(val);
end;

function TgsJsonImplLk.add(val: byte): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  lst.Add(Integer(val));
end;

function TgsJsonImplLk.add(val: boolean): igsJson;
begin
  result := self;
  var lst := getAsList(FJson, FOwned);
  lst.Add(val);
end;

function TgsJsonImplLk.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson is TlkJSONobject then
    result := TlkJSONobject(FJson).IndexOfName(name) >= 0;
end;

function TgsJsonImplLk.ToObj: igsJson;
begin
  result := self;
  if not (FJson is TlkJSONobject) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TlkJSONobject.Generate;
    FOwned := true;
  end;
end;

function TgsJsonImplLk.ToArray: igsJson;
begin
  result := self;
  if not (FJson is TlkJSONlist) then begin
    if FOwned and (FJson <> nil) then FJson.Free;
    FJson := TlkJSONlist.Generate;
    FOwned := true;
  end;
end;

{ TgsJsonImplLkFactory }

function TgsJsonImplLkFactory.getAuthor: string;
begin
  result := 'Leonid Koninin';
end;

function TgsJsonImplLkFactory.getTitle: string;
begin
  result := 'LkJSON';
end;

function TgsJsonImplLkFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplLkFactory.getId: string;
begin
  result := 'lkjson';
end;

function TgsJsonImplLkFactory.getJson: igsJson;
begin
  result := TgsJsonImplLk.Create;
end;

initialization

addImplementation(TgsJsonImplLkFactory.Create);

end.
