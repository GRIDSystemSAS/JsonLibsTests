///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gs.json.impl.gsJson;

interface


uses sysutils
     ,classes
     ,gs.Json
     ,gs.jsonCore;
type

TgsJson = class(TInterfacedObject,igsJson)
private
protected
  FJson : TJsonValue;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; Override;

  function parse(aJsonStr : string) : igsJson;

  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;

  //Array.
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;
  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;


  //Add an object.
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  //String
  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;

  //int
  function get(name : string; var value : integer) : igsJson; Overload;
  function get(index : integer; var value : integer) : igsJson; overload;

  //Double
  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;

  //boolean
  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;


  //Object/Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  function jsonElementCount : integer;
  function jsonType : TgsJsonElementType;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;


  //Base type easy access.
  function asString(name : String) : string;
  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload; //Obj Or array !
  function asObj(index : integer) : igsJson; overload; //Obj Or array !

  function isNameExists(name : String) : boolean;

  //Convert;
  function ToObj : igsJson;
  function ToArray : igsJson;
end;


TgsJsonFactory = class(TInterfacedObject,igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;


implementation

//Tools

function valueTypeToJsonElementType(v : TJsonValueType) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  case v of
    jvNone, jvNull: result := TgsJsonElementType.etEmpty;
    jvString: result := TgsJsonElementType.etString;
    jvNumber: result := TgsJsonElementType.etNumber;
    jvBoolean: result := TgsJsonElementType.etBoolean;
    jvObject: result := TgsJsonElementType.etJson;
    jvArray: result := TgsJsonElementType.etJsonArray;
  end;
end;

procedure extractValue(source : TJSONValue; var value : igsJson);
begin

  if not assigned(value) then
    value := TgsJson.Create;  //DO NOT call "createJson" : It can be give you another impl (!) - And it is slow.;

  //gs.JsonCore wrap a modified version of Json4Delphi, which owned the object.


  if TgsJson(value).FOwned then
    TgsJson(value).FJson.Free;
  TgsJson(value).FJson := Source;
  TgsJson(value).FOwned := false;
  TgsJson(value).FJson.ValueType := source.ValueType;  /// !!!

  //Perhpaps, we should be forced, in obvious case, to "rebuild" from string the json,
  //in the name of memory management.
  //Share object between json entity is a frail way.
  //  if not assigned(value) then
  //    value := ;
  //value.parse(source.Stringify);
end;

{ TgsJson }

function TgsJson.put(name: string; val: double): igsJson;
begin
  result := self;
  FJson.AsObject.Put(name,val);
end;

function TgsJson.put(name, val: string): igsJson;
begin
  result := self;
  FJson.AsObject.Put(name,val);
end;


function TgsJson.put(vals: array of const): igsJson;
begin
  result := self;

  var la := TJsonArray.Create(nil);
  try
    for var i := low(vals) to High(vals) do begin
      case vals[i].VType of
        vtString : la.Put(String(vals[i].VString^));
        vtWideString : la.Put(String(vals[i].VWideString));
        vtUnicodeString : la.Put(UnicodeString(vals[i].VUnicodeString));
        vtInteger : la.Put(vals[i].VInteger);
        vtBoolean : la.Put(vals[i].VBoolean);
        vtExtended : la.Put(vals[i].VExtended^);
        vtInterface : begin
          var val : igsJson;
          val := igsJson(vals[i].VInterface);
          la.put(val.stringify);
        end;
        vtObject : begin
          la.put(TJsonValue(vals[i].vObject));
        end;
      end;
    end;

    case FJson.ValueType of
      jvNone,
      jvNull: begin
        FJson.AsArray; //empty array.;
        FJson.AsArray.Assign(la);
      end;
      jvArray: begin
        //Merge array
        for var i := low(vals) to High(vals) do
          FJson.AsArray.Put(la.Items[i]);
      end;
      jvString,
      jvNumber,
      jvBoolean: raise Exception.Create('json not empty : not allowed to insert array in simple type. Use array or object.');
      jvObject: raise Exception.Create('json not empty : not allowed to insert array : named it.');
    end;
  finally
    FreeAndNil(la);
  end;
end;

function TgsJson.put(name: string; vals : array of const): igsJson;
begin
  result := self;

  var ll := TJsonArray.Create(nil);
  try
    for var i := low(vals) to High(vals) do begin
      case vals[i].VType of
        vtString : ll.Put(String(vals[i].VString^));
        vtWideString : ll.Put(String(vals[i].VWideString));
        vtUnicodeString : ll.Put(UnicodeString(vals[i].VUnicodeString));
        vtInteger : ll.Put(vals[i].VInteger);
        vtBoolean : ll.Put(vals[i].VBoolean);
        vtExtended : ll.Put(vals[i].VExtended^);
        vtObject : begin
          ll.put(TJsonValue(vals[i].vObject));
        end;
      end;
    end;

    if FJson.ValueType in [TJsonValueType.jvNull,TJsonValueType.jvNone] then begin
      FJson.AsObject;
    end;

    case FJson.ValueType of
      jvObject:
      begin
        FJson.AsObject.Put(name,ll);
      end;
      jvArray:
      begin
        //Merge array
        for var i := 0 to ll.Count-1 do
          FJson.AsArray.Put(ll.Items[i]);
      end;
    end;
  finally
    freeAndNil(ll);
  end;
end;

function TgsJson.put(val: igsJson): igsJson;
begin
  result := self;
  if (FJson.ValueType in [TJsonValueType.jvNull,TJsonValueType.jvNone])  then begin
    FJson.AsArray;
  end;

  case FJson.ValueType of
    jvObject:
    begin
      if FJson.AsObject.Count=0 then
        FJson.AsArray //Mute into an array.
      else
        raise Exception.Create('json root is an object : not allowed to embede an object init another object without named it.');
    end;
    jvArray: //all ok.
    begin
      //Merge array
      //var lp : TJsonValue;
      //lp := FJson.AsArray.Add;
      //extractValue(lp,val);
    End;
  end;
  FJson.AsArray.Add.parse(val.stringify);
end;


function TgsJson.put(name: string; val: igsJson): igsJson;
var aux: TgsJson;
begin
  result := self;

  if FJson.ValueType in [TJsonValueType.jvNull,TJsonValueType.jvNone] then begin
    FJson.AsObject;
  end;

  case FJson.ValueType of
      jvObject:
      begin
//        var lp : TJsonValue;
//        lp.Parse(val.stringify);
//        FJson.AsObject.Put(name,lp);
        aux:= TgsJson.Create;
        aux.parse(val.stringify);
        FJson.AsObject.Put(name,aux.FJson);

{        //Is this element already exits ?
        if lp.ValueType = TJsonValueType.jvNone then begin
          //no !
          case val.jsonType of
            TgsJsonElementType.etJson : lp.AsObject;
            TgsJsonElementType.etJsonArray : lp.AsArray;
            TgsJsonElementType.etEmpty,
            TgsJsonElementType.etNull : ;
            TgsJsonElementType.etNumber : lp.AsNumber;
            TgsJsonElementType.etString : lp.AsString;
            TgsJsonElementType.etBoolean : lp.AsBoolean;
          end
        end;
        extractValue(lp,val);
        FJson.AsObject.Put(name,lp);
 }
      end;
      jvArray:
      begin
        raise Exception.Create('json root is an array : not allowed to add named item.');
      end;
    end;
end;

function TgsJson.add(val: igsJson): igsJson;
begin
  result := self;

  case FJson.ValueType of
    jvObject: begin
      raise Exception.Create('json root is an object. "Add" is specific to array');
    end
    else
      if val.jsonType = etJson then begin
        FJson.AsArray.Put(TgsJson(val).FJson);
      end
      else begin //array
        //VGS Note : I choose to merge array together, but perhaps array of array is an option ?
        FJson.AsArray.Merge(TgsJson(val).FJson.AsArray);
      end;
  end;
end;

function TgsJson.add(val: double): igsJson;
begin
  result := self;
  assert(FJson.ValueType = jvArray,'add(double) : only for array.');
  FJson.AsArray.Put(val);
end;

function TgsJson.add(val: string): igsJson;
begin
  result := self;
  assert(FJson.ValueType = jvArray,'add(string) : only for array.');
  FJson.AsArray.Put(val);
end;

function TgsJson.add(val: integer): igsJson;
begin
  result := self;
  assert(FJson.ValueType = jvArray,'add(integer) : only for array.');
  FJson.AsArray.Put(val);
end;

function TgsJson.add(val: boolean): igsJson;
begin
  result := self;
  assert(FJson.ValueType = jvArray,'add(boolean) : only for array.');
  FJson.AsArray.Put(val);
end;

function TgsJson.add(val: byte): igsJson;
begin
  result := self;
  assert(FJson.ValueType = jvObject,'add(bate) : only for array.');
  FJson.AsArray.Put(val);
end;

function TgsJson.asBoolean(name: String): Boolean;
begin
  get(name,result);
end;

function TgsJson.asInteger(name: String): integer;
begin
  get(name,result);
end;

function TgsJson.asNumber(name: String): double;
begin
  get(name,result);
end;

function TgsJson.asObj(index: integer): igsJson;
begin
  get(index,result);
end;

function TgsJson.asObj(name: String): igsJson;
begin
  get(name,result);
end;

function TgsJson.asString(name: String): string;
begin
  get(name,result);
end;

function TgsJson.clear: igsJson;
begin
  result := self;
  FJson.Clear;
end;

constructor TgsJson.Create;
begin
  FJson := TJsonValue.Create(nil);
  FOwned := true;
end;

destructor TgsJson.Destroy;
begin
  if FOwned then
    FreeAndNil(FJson);
  inherited;
end;

function TgsJson.get(name: string; var value: igsJson): igsJson;
begin
  result := self;
  var lp : TJSONValue;

  case FJson.ValueType of
    jvObject: begin
      lp := FJson.AsObject.Values[name]; //Lp is own by FJson
    end;
    jvNone: begin
      lp := TJsonValue.Create(FJson); //Current json is empty, add a new Json objet in it.
    end;
    else
      raise Exception.Create(' TgsJson.get : Not object - Name Not available');
  end;

  extractValue(lp,value);
end;

function TgsJson.get(index: integer; var value: igsJson): igsJson;
var lp : TJSONValue;
begin
  result := self;
  lp := nil;

  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      lp := FJson.AsObject.Pairs[index].Value;
    end;
    jvArray: begin
      assert(index<FJson.AsArray.count);
      lp := FJson.AsArray.Items[index];
    end;
  end;

  extractValue(lp,value);
end;

function TgsJson.isNameExists(name: String): boolean;
begin
  result := false;
  if FJson.ValueType = jvObject then
    result := FJson.AsObject.Find(name)>-1;
end;

function TgsJson.get(index: integer; var value: Double): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      value := Double(FJson.AsObject.Pairs[index].Value.AsNumber);
    end;
    jvArray: begin
      assert(index<FJson.AsArray.count);
      value := Double(FJson.AsArray.Items[index].AsNumber);
    end;
  end;
end;

function TgsJson.get(name: string; var value: Boolean): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      value := FJson.AsObject.Values[name].AsBoolean;
    end;
    else
      raise Exception.Create(' TgsJson.get : Not Boolean - Name Not available');
  end;
end;

function TgsJson.get(index: integer; var value: Boolean): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      value := FJson.AsObject.Pairs[index].Value.AsBoolean;
    end;
    jvArray: begin
      assert(index<FJson.AsArray.count);
      value := FJson.AsArray.Items[index].AsBoolean;
    end;
  end;end;

function TgsJson.get(index: integer; var value: integer): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      value := FJson.AsObject.Pairs[index].Value.AsInteger;
    end;
    jvArray: begin
      assert(index<FJson.AsArray.count);
      value := FJson.AsArray.Items[index].AsInteger;
    end;
  end;
end;

function TgsJson.get(index: integer; var value: string): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      value := FJson.AsObject.Pairs[index].Value.AsString;
    end;
    jvArray: begin
      assert(index<FJson.AsArray.count);
      value := FJson.AsArray.Items[index].AsString;
    end;
  end;
end;

function TgsJson.jsonElementCount: integer;
begin
  case FJson.ValueType of
    jvObject: begin
      result := FJson.AsObject.count;
    end;
    jvArray: begin
      result := FJson.AsArray.count;
    end;
    jvString,jvNumber,jvBoolean : begin
      result := 0;
    end
    else //jvNone, jvNull
      result := -1;
  end;
end;

function TgsJson.jsonElementName(index: integer): string;
begin
  result := '';
  case FJson.ValueType of
    jvObject: begin
      assert(index<FJson.AsObject.count);
      result := FJson.AsObject.Pairs[index].Name;
    end;
//    else
//      raise Exception.Create(' TgsJson.jsonElementName : Name Not available');
  end;
end;

function TgsJson.jsonElementType(index: integer): TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  case FJson.ValueType of
    jvObject: begin
      result := valueTypeToJsonElementType(FJson.AsObject.Pairs[index].Value.ValueType);
    end;
    jvArray: begin
      result := valueTypeToJsonElementType(FJson.AsArray.Items[index].ValueType);
    end;
//    else
//      raise Exception.Create(' TgsJson.jsonElementType : indexed type not available');
  end;
end;

function TgsJson.jsonType: TgsJsonElementType;
begin
  result := valueTypeToJsonElementType(FJson.ValueType);
end;

function TgsJson.get(name: string; var value: string): igsJson;
begin
  result := self;

  case FJson.ValueType of
    jvObject: begin
      value := FJson.AsObject.Values[name].AsString;
    end;
    else
      raise Exception.Create(' TgsJson.get : Not string - Name Not available');
  end;
end;

function TgsJson.get(name: string; var value: integer): igsJson;
begin
  result := self;

  case FJson.ValueType of
    jvObject: begin
      value := FJson.AsObject.Values[name].AsInteger;
    end;
    else
      raise Exception.Create(' TgsJson.get : Not Integer - Name Not available');
  end;
end;

function TgsJson.get(name: string; var value: Double): igsJson;
begin
  result := self;
  case FJson.ValueType of
    jvObject: begin
      value := FJson.AsObject.Values[name].AsNumber;
    end;
    else
      raise Exception.Create(' TgsJson.get : Not Double - Name Not available');
  end;
end;

function TgsJson.parse(aJsonStr: string): igsJson;
begin
  result := self;
  FJson.Parse(aJsonStr.trim);
end;

function TgsJson.put(name: string; val: boolean): igsJson;
begin
  result := self;
  FJson.AsObject.Put(name,val);
end;

function TgsJson.stringify: string;
begin
  result:= fjson.Stringify;
end;

function TgsJson.ToArray: igsJson;
begin
  result := Self;
  FJson.AsArray;
end;

function TgsJson.ToObj: igsJson;
begin
  result := self;
  FJson.AsObject;
end;

function TgsJson.stringify(var aStr: string): igsJson;
begin
  result := self;
  aStr := fjson.Stringify;
end;


{ TgsJsonFactory }

function TgsJsonFactory.getAuthor: string;
begin
  result := 'Vincent Gsell (VincentGsell.fr) - Front Interface and feep fixes. Core @Json4Delphi';
end;

function TgsJsonFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonFactory.getId: string;
begin
  result := 'gsJson';
end;

function TgsJsonFactory.getJson: igsJson;
begin
  result := TgsJson.Create;
end;

function TgsJsonFactory.getTitle: string;
begin
  result := 'gsJson lib';
end;

initialization

addImplementation(TgsJsonFactory.Create);

end.
