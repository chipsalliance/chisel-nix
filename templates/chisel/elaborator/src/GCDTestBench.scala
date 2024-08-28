// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.{GCDTestBench, GCDTestBenchParameter, TestVerbatimParameter}
import org.chipsalliance.gcd.elaborator.Elaborator
import org.chipsalliance.gcd.elaborator.GCD.GCDParameterMain

object GCDTestBench extends Elaborator {
  @main
  case class GCDTestBenchParameterMain(
    @arg(name = "testVerbatimParameter") testVerbatimParameter: TestVerbatimParameterMain,
    @arg(name = "gcdParameter") gcdParameter:                   GCDParameterMain,
    @arg(name = "timeout") timeout:                             Int,
    @arg(name = "testSize") testSize:                           Int) {
    def convert: GCDTestBenchParameter = GCDTestBenchParameter(
      testVerbatimParameter.convert,
      gcdParameter.convert,
      timeout,
      testSize
    )
  }

  case class TestVerbatimParameterMain(
    @arg(name = "useAsyncReset") useAsyncReset:       Boolean,
    @arg(name = "initFunctionName") initFunctionName: String,
    @arg(name = "dumpFunctionName") dumpFunctionName: String,
    @arg(name = "clockFlipTick") clockFlipTick:       Int,
    @arg(name = "resetFlipTick") resetFlipTick:       Int) {
    def convert: TestVerbatimParameter = TestVerbatimParameter(
      useAsyncReset:    Boolean,
      initFunctionName: String,
      dumpFunctionName: String,
      clockFlipTick:    Int,
      resetFlipTick:    Int
    )
  }

  implicit def TestVerbatimParameterMainParser: ParserForClass[TestVerbatimParameterMain] =
    ParserForClass[TestVerbatimParameterMain]

  implicit def GCDParameterMainParser: ParserForClass[GCDParameterMain] =
    ParserForClass[GCDParameterMain]

  implicit def GCDTestBenchParameterMainParser: ParserForClass[GCDTestBenchParameterMain] =
    ParserForClass[GCDTestBenchParameterMain]

  @main
  def config(@arg(name = "parameter") parameter: GCDTestBenchParameterMain) =
    configImpl(parameter.convert)

  @main
  def design(
    @arg(name = "parameter") parameter:    os.Path,
    @arg(name = "run-firtool") runFirtool: mainargs.Flag,
    @arg(name = "target-dir") targetDir:   os.Path
  ) =
    designImpl[GCDTestBench, GCDTestBenchParameter](parameter, runFirtool.value, targetDir)

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args)
}
