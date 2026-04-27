///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.validator;

interface

uses
  GS.json
  , System.Classes
  ;

type

  IJsonSchemaValidator = interface
    ['{36EEE360-5820-4CC8-8A20-E8249DEFEB4B}']
    function Validate(const AJson: igsJson): boolean;
  end;

  TJsonSchemaValidator = class(TInterfacedObject, IJsonSchemaValidator)
  private
    FSchema: igsJson;
    FSilent: boolean;
    FErrors: TStringList;
    function ResolveRef(const ARef: string): igsJson;
    procedure ValidateConst(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateNode(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateObject(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateArray(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateString(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateNumber(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateBoolean(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateOneOf(const ANode: igsJson; const ASchema: igsJson; const APath: string);
    procedure ValidateType(const Anode: igsJson; const ASchema: igsJson; const APath: string);
  public
    constructor Create(const ASchema: igsJson; const ASilent: boolean = false);
    destructor Destroy; override;
    function Validate(const AJson: igsJson): boolean;
  end;

implementation

uses
  System.SysUtils
  , RegularExpressions
  ;

const
  ROOT_PATH='root';
  LEVEL_DOWN = '%s.%s';
  REF_PREFIX = '#/definitions/';

constructor TJsonSchemaValidator.Create(const ASchema: igsJson; const ASilent: boolean = false);
begin
  inherited Create;
  FSchema := ASchema;
  FSilent := ASilent;
  FErrors := TStringList.Create;
end;

destructor TJsonSchemaValidator.Destroy;
begin
  FreeAndNil(FErrors);

  inherited Destroy;
end;

function TJsonSchemaValidator.ResolveRef(const ARef: string): igsJson;
var
  lDefName: string;
  lDefinitions: igsJson;
begin
  result := nil;

  if not ARef.StartsWith(REF_PREFIX) then begin
    FErrors.Add(format('Reference not supported : %s', [ARef]));
  end;
  lDefName :=  ARef.Substring(REF_PREFIX.Length);

  if FSchema.isNameExists('definitions') then begin
    lDefinitions := cloneJson(FSchema.asObj('definitions'));
    if lDefinitions.isNameExists(lDefName) then begin
      result := cloneJson(lDefinitions.asObj(lDefName));
    end else begin
      FErrors.Add(format('Definition %s is missing.', [lDefName]));
    end;
  end else begin
    FErrors.Add('Definitions are missing.');
  end;
end;

procedure TJsonSchemaValidator.ValidateConst(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lConstValue: igsJson;
begin
  if ASchema.isNameExists('const') then begin
    lConstValue := cloneJson(ASchema.asObj('const'));
    if ANode.stringify <> lConstValue.stringify then begin
      FErrors.Add(format('%s: Constant value %s expected, found %s', [APath, ANode.stringify, lConstValue.stringify]));
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateOneOf(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lOneOf,
  lSubSchema: igsJson;
  i: integer;
  lSubValidator: IJsonSchemaValidator;
  lMatchCount: integer;
begin
  lMatchCount := 0;
  if ASchema.isNameExists('oneOf') then begin
    lOneOf := cloneJson(ASchema.asObj('oneOf'));

    for i:=0 to lOneOf.jsonElementCount -1 do begin
      lSubSchema := cloneJson(lOneOf.AsObj(i));
      lSubSchema.put('definitions', FSchema.asObj('definitions'));
      lSubValidator := TJsonSchemaValidator.Create(lSubSchema, true);
      if lSubValidator.Validate(ANode) then begin
        inc(lMatchCount);
      end;
    end;

    if lMatchCount<>1 then begin
      FErrors.Add(format('%s: 1 match expected, got %d', [APath, lMatchCount]));
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateBoolean(const ANode: igsJson; const ASchema: igsJson; const APath: string);
begin
  if not(ANode.jsonType = etBoolean) then begin
    FErrors.Add(format('%s must be a boolean for %s', [ANode.stringify, ASchema.stringify]));
  end;

  if (ANode.stringify <> 'true') and (ANode.stringify <> 'false') then begin
    FErrors.Add(format('Unrecognized boolean value %s', [ANode.stringify]));
  end;
end;

procedure TJsonSchemaValidator.ValidateNumber(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lMinimum: Double;
  lValue: Double;
  lMaxmimum: Double;
begin
  if not(ANode.jsonType = etNumber) then begin
    FErrors.Add(format('%s must be a integer for %s', [ANode.stringify, ASchema.stringify]));
  end;

  lValue := StrToFloat(ANode.stringify);

  if ASchema.isNameExists('minimum') then begin
    ASchema.get('minimum', lMinimum);
    if lValue<lMinimum then begin
      FErrors.Add(format('%s: %f must be greater than %f', [APath, lValue, lMinimum]));
    end;
  end;

  if ASchema.isNameExists('maximum') then begin
    ASchema.get('maximum', lMaxmimum);
    if lValue>lMaxmimum then begin
      FErrors.Add(format('%s: %f must be lower than %f', [APath, lValue, lMaxmimum]));
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateString(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lValue: string;
  lMinLength: integer;
  lPattern: string;
begin
  if not(ANode.jsonType = etString) then begin
    FErrors.Add(format('%s must be a string for %s', [ANode.stringify, ASchema.stringify]));
  end;

  lValue := ANode.stringify;

  if ASchema.isNameExists('minLength') then begin
    ASchema.get('minLength', lMinLength);
    if lValue.Length<lMinLength then begin
      FErrors.Add(format('%s: %s length must be greater than %d', [APath, lValue, lMinLength]));
    end;
  end;

  if ASchema.isNameExists('pattern') then begin
    ASchema.get('pattern', lPattern);
    if not TRegEx.IsMatch(lValue, lPattern) then begin
      FErrors.Add(format('%s: %s must match %s pattern', [APath, lValue, lPattern]));
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateArray(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lMinItems,
  lMaxItems: integer;
  lItems: igsJson;
  i: integer;
begin
  if not(ANode.jsonType = etJsonArray) then begin
    FErrors.Add(format('%s must be a Json array', [ANode.stringify]));
  end;

  if ASchema.isNameExists('minItems') then begin
    ASchema.get('minItems', lMinItems);
    if ANode.jsonElementCount<lMinItems then begin
      FErrors.Add(format('%s: Minimal length for array %s is %d', [APath, ANode.stringify, lMinItems]));
    end;
  end;

   if ASchema.isNameExists('maxItems') then begin
    ASchema.get('maxItems', lMaxItems);
    if ANode.jsonElementCount>lMaxItems then begin
      FErrors.Add(format('%s: Maximal length for array %s is %d', [APath, ANode.stringify, lMaxItems]));
    end;
  end;

   if ASchema.isNameExists('items') then begin
    lItems := cloneJson(ASchema.asObj('items'));
    for i:=0 to ANode.jsonElementCount -1 do begin
      ValidateNode(ANode.asObj(i), lItems, Format('%s[%d]', [APath, i]));
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateObject(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  i: integer;
  lRequired,
  lProperties: igsJson;
  lValue: string;
  lAllowedKeys: TStringList;
  lAdditionalProperties: boolean;
begin
  if not(ANode.jsonType = etJson) then begin
    FErrors.Add(format('%s: %s must be a Json object', [APath, ANode.stringify]));
  end;

  if ASchema.isNameExists('required') then begin
    lRequired := cloneJson(ASchema.asObj('required'));
    for i:=0 to lRequired.jsonElementCount -1 do begin
      lRequired.get(i, lValue);
      if not(ANode.isNameExists(lValue)) then begin
        FErrors.Add(format('%s: %s is required', [APath, lValue]));
      end;
    end;
  end;
  lAllowedKeys := TStringList.Create;
  try
    if ASchema.isNameExists('properties') then begin
      lProperties := cloneJson(ASchema.asObj('properties'));
      for i:=0 to lProperties.jsonElementCount -1 do begin
        lValue := lProperties.jsonElementName(i);
        lAllowedKeys.Add(lValue);
        if ANode.isNameExists(lValue) then begin
          ValidateNode(ANode.asObj(lValue), lProperties.asObj(i), format(LEVEL_DOWN, [APath, lValue]));
        end;
      end;
    end;

    if ASchema.isNameExists('additionalProperties') then begin
      if ASchema.asObj('additionalProperties').jsonType = etBoolean then begin
        ASchema.get('additionalProperties', lAdditionalProperties);
        if not(lAdditionalProperties) then begin
          for i:=0 to ANode.jsonElementCount -1 do begin
            if lAllowedKeys.indexOf(ANode.jsonElementName(i)) < 0 then begin
              FErrors.Add(format('%s: %s is not allowed', [APath, ANode.jsonElementName(i)]));
            end;
          end;
        end;
      end else begin
        for i:=0 to ANode.jsonElementCount -1 do begin
          ValidateNode(ANode.asObj(i), ASchema.asObj('additionalProperties'), format(LEVEL_DOWN, [APath, lValue]));
        end;
      end;
    end;

  finally
    FreeAndNil(lAllowedKeys);
  end;
end;

procedure TJsonSchemaValidator.ValidateType(const ANode: igsJson; const ASchema: igsJson; const APath: string);
begin
  if ASchema.isNameExists('type') then begin
    if ASchema.asString('type') = 'object' then begin
      ValidateObject(ANode, ASchema, APath);
    end else if ASchema.asString('type') = 'array' then begin
      ValidateArray(ANode, ASchema, APath);
    end else if ASchema.asString('type') = 'string' then begin
      ValidateString(ANode, ASchema, APath);
    end else if ASchema.asString('type') = 'integer' then begin
      ValidateNumber(ANode, ASchema, APath);
    end else if ASchema.asString('type') = 'number' then begin
      ValidateNumber(ANode, ASchema, APath);
    end else if ASchema.asString('type') = 'boolean' then begin
      ValidateBoolean(ANode, ASchema, APath);
    end;
  end;
end;

procedure TJsonSchemaValidator.ValidateNode(const ANode: igsJson; const ASchema: igsJson; const APath: string);
var
  lEffectiveSchema: igsJson;
  lRef: string;
begin
  if ASchema.isNameExists('$ref') then begin
    ASchema.get('$ref', lRef);
    lEffectiveSchema := ResolveRef(lRef)
  end else
  begin
    lEffectiveSchema := ASchema;
  end;

  ValidateOneOf(ANode, lEffectiveSchema, APath);
  ValidateConst(ANode, lEffectiveSchema, APath);
  ValidateType(ANode, lEffectiveSchema, APath);
end;

function TJsonSchemaValidator.Validate(Const AJson: igsJson): boolean;
begin
  FErrors.Clear;
  ValidateNode(AJson, FSchema, ROOT_PATH);
  result := FErrors.Count = 0;
end;

end.
