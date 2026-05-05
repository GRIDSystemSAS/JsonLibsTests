///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
program gsJsonTests;


///// UI Selection - Pick only 1! //////////////////////////////
{DEFINE UseVCL}
{DEFINE UseFMX}
{$DEFINE UseWinConsole}
////////////////////////////////////////////////////////////////


{$IFDEF UseWinConsole}
{$DEFINE UseConsole}
{$ENDIF}

{$IFDEF UseConsole}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  {$IFDEF UseVCL}
  VCL.Forms,
  {$ENDIF }
  {$IFDEF UseFMX}
  FMX.Forms,
  {$ENDIF }
  {$IFDEF UseConsole}
  DUnitX.ConsoleWriter.Base,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  DUnitX.Loggers.Text,
  DUnitX.Loggers.XML.xUnit,
  {$ENDIF }
  {$IFDEF UseWinConsole}
  DUnitX.Windows.Console,
  WinAPI.Windows,
  WinAPI.Messages,
  {$ENDIF }
  System.SysUtils,
  DUnitX.Generics,
  DUnitX.InternalInterfaces,
  DUnitX.WeakReference,
  DUnitX.FixtureResult,
  DUnitX.RunResults,
  DUnitX.Test,
  DUnitX.TestFixture,
  DUnitX.TestFramework,
  DUnitX.TestResult,
  DUnitX.TestRunner,
  DUnitX.Utils,
  DUnitX.IoC,
  DUnitX.MemoryLeakMonitor.Default,
  DUnitX.DUnitCompatibility,
  GS.System.CommandLineParser in '..\GS.System.CommandLineParser.pas',
  gsJson.tests.main in 'gsJson.tests.main.pas',
  gsJson.tests.jsonReport in 'gsJson.tests.jsonReport.pas',
  gs.Json in '..\src\gs.Json.pas',
  gs.jsonCore in '..\src\impl\gsJson\gs.jsonCore.pas',
  gs.json.impl.gsJson in '..\src\impl\gsJson\gs.json.impl.gsJson.pas',
  gs.json.impl.delphiJson in '..\src\impl\embDelphiJson\gs.json.impl.delphiJson.pas',
  chimera.json in '..\src\impl\chimera\src\chimera.json.pas',
  chimera.json.parser in '..\src\impl\chimera\src\chimera.json.parser.pas',
  chimera.json.variants in '..\src\impl\chimera\src\chimera.json.variants.pas',
  gs.json.impl.chimera in '..\src\impl\chimera\gs.json.impl.chimera.pas',
  PasDblStrUtils in '..\src\impl\bero\src\pasdblstrutils\src\PasDblStrUtils.pas',
  PasJSON in '..\src\impl\bero\src\src\PasJSON.pas',
  gs.json.impl.beroJson in '..\src\impl\bero\gs.json.impl.beroJson.pas',
  gs.json.impl.lkJson in '..\src\impl\lkJson\gs.json.impl.lkJson.pas',
  jsonDoc in '..\src\impl\jsonDoc\src\jsonDoc.pas',
  gs.json.impl.jsonDoc in '..\src\impl\jsonDoc\gs.json.impl.jsonDoc.pas',
  gs.json.impl.mcJson in '..\src\impl\mcJson\gs.json.impl.mcJson.pas',
  McJSON in '..\src\impl\mcJson\src\src\McJSON.pas',
  gs.json.impl.json4Delphi in '..\src\impl\json4Delphi\gs.json.impl.json4Delphi.pas',
  Jsons in '..\src\impl\json4Delphi\src\src\Jsons.pas',
  JsonsUtilsEx in '..\src\impl\json4Delphi\src\src\JsonsUtilsEx.pas',
  JsonDataObjects in '..\src\impl\jdo\src\Source\JsonDataObjects.pas',
  gs.json.impl.jdo in '..\src\impl\jdo\gs.json.impl.jdo.pas',
  XSuperObject in '..\src\impl\xSuperObject\src\XSuperObject.pas',
  XSuperJSON in '..\src\impl\xSuperObject\src\XSuperJSON.pas',
  gs.json.impl.xSuperObject in '..\src\impl\xSuperObject\gs.json.impl.xSuperObject.pas',
  superobject in '..\src\impl\superObject\src\Lib\superobject.pas',
  superdate in '..\src\impl\superObject\src\Lib\superdate.pas',
  supertimezone in '..\src\impl\superObject\src\Lib\supertimezone.pas',
  supertypes in '..\src\impl\superObject\src\Lib\supertypes.pas',
  gs.json.impl.superObject in '..\src\impl\superObject\gs.json.impl.superObject.pas',
  uJSON in '..\src\impl\myJson\src\uJSON.pas',
  gs.json.impl.myJson in '..\src\impl\myJson\gs.json.impl.myJson.pas',
  dwsJSON in '..\src\impl\dwsJson\src\Source\dwsJSON.pas',
  dwsUtils in '..\src\impl\dwsJson\src\Source\dwsUtils.pas',
  dwsStrings in '..\src\impl\dwsJson\src\Source\dwsStrings.pas',
  dwsXPlatform in '..\src\impl\dwsJson\src\Source\dwsXPlatform.pas',
  dwsXXHash in '..\src\impl\dwsJson\src\Source\dwsXXHash.pas',
  dwsUnicode in '..\src\impl\dwsJson\src\Source\dwsUnicode.pas',
  dwsUTF8 in '..\src\impl\dwsJson\src\Source\dwsUTF8.pas',
  gs.json.impl.dwsJson in '..\src\impl\dwsJson\gs.json.impl.dwsJson.pas',
  DataObjects2 in '..\src\impl\dynamicDataObjects\src\src\DataObjects2.pas',
  DataObjects2JSON in '..\src\impl\dynamicDataObjects\src\src\DataObjects2JSON.pas',
  DataObjects2Streamers in '..\src\impl\dynamicDataObjects\src\src\DataObjects2Streamers.pas',
  DataObjects2Utils in '..\src\impl\dynamicDataObjects\src\src\DataObjects2Utils.pas',
  StreamCache in '..\src\impl\dynamicDataObjects\src\src\StreamCache.pas',
  StringBTree in '..\src\impl\dynamicDataObjects\src\src\StringBTree.pas',
  SlotNameIndex in '..\src\impl\dynamicDataObjects\src\src\SlotNameIndex.pas',
  unicodedata in '..\src\impl\dynamicDataObjects\src\src\unicodedata.pas',
  VarInt in '..\src\impl\dynamicDataObjects\src\src\VarInt.pas',
  gs.json.impl.dynamicDataObjects in '..\src\impl\dynamicDataObjects\gs.json.impl.dynamicDataObjects.pas',
  Neslib.Json in '..\src\impl\neslibJson\src\Neslib.Json.pas',
  Neslib.Json.IO in '..\src\impl\neslibJson\src\Neslib.Json.IO.pas',
  Neslib.Json.Types in '..\src\impl\neslibJson\src\Neslib.Json.Types.pas',
  Neslib.Utf8 in '..\src\impl\neslibJson\src\Neslib\Neslib.Utf8.pas',
  Neslib.Hash in '..\src\impl\neslibJson\src\Neslib\Neslib.Hash.pas',
  Neslib.SysUtils in '..\src\impl\neslibJson\src\Neslib\Neslib.SysUtils.pas',
  gs.json.impl.neslibJson in '..\src\impl\neslibJson\gs.json.impl.neslibJson.pas',
  Grijjy.Bson in '..\src\impl\grijjyBson\src\Grijjy.Bson.pas',
  Grijjy.Bson.IO in '..\src\impl\grijjyBson\src\Grijjy.Bson.IO.pas',
  Grijjy.SysUtils in '..\src\impl\grijjyBson\src\Grijjy.SysUtils.pas',
  Grijjy.DateUtils in '..\src\impl\grijjyBson\src\Grijjy.DateUtils.pas',
  Grijjy.BinaryCoding in '..\src\impl\grijjyBson\src\Grijjy.BinaryCoding.pas',
  gs.json.impl.grijjyBson in '..\src\impl\grijjyBson\gs.json.impl.grijjyBson.pas',
  mormot.core.base in '..\src\impl\mormot\src\src\core\mormot.core.base.pas',
  mormot.core.os in '..\src\impl\mormot\src\src\core\mormot.core.os.pas',
  mormot.core.os.security in '..\src\impl\mormot\src\src\core\mormot.core.os.security.pas',
  mormot.core.unicode in '..\src\impl\mormot\src\src\core\mormot.core.unicode.pas',
  mormot.core.text in '..\src\impl\mormot\src\src\core\mormot.core.text.pas',
  mormot.core.datetime in '..\src\impl\mormot\src\src\core\mormot.core.datetime.pas',
  mormot.core.rtti in '..\src\impl\mormot\src\src\core\mormot.core.rtti.pas',
  mormot.core.buffers in '..\src\impl\mormot\src\src\core\mormot.core.buffers.pas',
  mormot.core.data in '..\src\impl\mormot\src\src\core\mormot.core.data.pas',
  mormot.core.json in '..\src\impl\mormot\src\src\core\mormot.core.json.pas',
  mormot.core.variants in '..\src\impl\mormot\src\src\core\mormot.core.variants.pas',
  gs.json.impl.mormot in '..\src\impl\mormot\gs.json.impl.mormot.pas',
  VSoft.YAML in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.pas',
  VSoft.YAML.Classes in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Classes.pas',
  VSoft.YAML.Parser in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Parser.pas',
  VSoft.YAML.Lexer in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Lexer.pas',
  VSoft.YAML.Writer in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Writer.pas',
  VSoft.YAML.Writer.JSON in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Writer.JSON.pas',
  VSoft.YAML.IO in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.IO.pas',
  VSoft.YAML.Utils in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Utils.pas',
  VSoft.YAML.TagInfo in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.TagInfo.pas',
  VSoft.YAML.StreamWriter in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.StreamWriter.pas',
  VSoft.YAML.Path in '..\src\impl\vsoftYaml\src\Source\VSoft.YAML.Path.pas',
  gs.json.impl.vsoftYaml in '..\src\impl\vsoftYaml\gs.json.impl.vsoftYaml.pas',
  uLkJSON in '..\src\impl\lkJson\src\uLkJSON.pas';

{$R *.res}

/////////////////////////////////////////////////////////////////////////
{$IFDEF UseVCL}
begin
  Application.Initialize;
  Application.CreateForm(TGUIVCLTestRunner, GUIVCLTestRunner);
  Application.Run;
{$ENDIF}
/////////////////////////////////////////////////////////////////////////
{$IFDEF UseFMX}
begin
  Application.Initialize;
  Application.CreateForm(TGUIXTestRunner, GUIXTestRunner);
  Application.Run;
{$ENDIF}
/////////////////////////////////////////////////////////////////////////
{$IFDEF UseConsole}
var
  runner : ITestRunner;
  results : IRunResults;
  logger : ITestLogger;
  nunitLogger : ITestLogger;
  cmd : iGSCommandLine;
  noVerbose, noWait : Boolean;
  jsonFile : string;

begin
   try
      ReportMemoryLeaksOnShutdown := true;

      // Parse command line with GS-Core parser (case-insensitive)
      cmd := gsCommandLineParser;
      cmd.registerParameter('help', ['h', '?'], 'Show this help message');
      cmd.registerParameter('noverbose', ['nv'], 'No console output, no wait');
      cmd.registerParameter('nowait', ['nw'], 'Console output but no wait for Enter at end');
      cmd.registerParameter('outputjson', ['oj', 'json'], 'Generate JSON report (optionally specify filename)');
      cmd.registerParameter('prettyprint', ['pp'], 'Print results table to console (requires --outputjson)');

      // Help
      if cmd.hasParameter('help') then
      begin
        System.Writeln('gsJsonTests - igsJson RFC 8259 compliance test suite');
        System.Writeln;
        System.Writeln('Usage: gsJsonTests.exe [options]');
        System.Writeln;
        cmd.getHelp;
        System.Writeln('Examples:');
        System.Writeln('  gsJsonTests.exe --nowait --outputjson');
        System.Writeln('  gsJsonTests.exe -nv -oj results.json --prettyprint');
        System.Writeln('  gsJsonTests.exe --noverbose --json --pp');
        Exit;
      end;

      noVerbose := cmd.hasParameter('noverbose');
      noWait := cmd.hasParameter('nowait') or noVerbose;

      // Resolve JSON output filename
      jsonFile := 'gsJsonTestResults.json';
      if cmd.hasParameter('outputjson') then
      begin
        var paramVal := cmd.getParameter('outputjson');
        if paramVal.Trim <> '' then
          jsonFile := paramVal.Trim;
      end;

      //Create the runner
      runner := TDUnitX.CreateRunner;
      runner.UseRTTI := True;

      //tell the runner how we will log things
      if not noVerbose then
      begin
        logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
        runner.AddLogger(logger);
      end;
      nunitLogger := TDUnitXXMLNUnitFileLogger.Create;
      runner.AddLogger(nunitLogger);

      //Run tests
      results := runner.Execute;

      // JSON report output
      if cmd.hasParameter('outputjson') then
      begin
        GenerateJsonReport(results, jsonFile);
        if not noVerbose then
          System.Writeln('JSON report written to: ' + jsonFile);
      end;

      // Pretty print table
      if cmd.hasParameter('prettyprint') then
      begin
        if not cmd.hasParameter('outputjson') then
        begin
          // Auto-generate JSON if not explicitly requested
          GenerateJsonReport(results, jsonFile);
        end;
        PrettyPrintReport(jsonFile);
      end;

      if not noWait then
      begin
        System.Write('Done.. press <Enter> key to quit.');
        System.Readln;
      end;

   except
      on E: Exception do
         System.Writeln(E.ClassName, ': ', E.Message);
   end;
{$ENDIF}
/////////////////////////////////////////////////////////////////////////

end.

