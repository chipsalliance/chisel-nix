// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.{GCDTestBench, GCDTestBenchParameter, TestVerbatimParameter}
import org.chipsalliance.gcd.elaborator.GCDMain.GCDParameterMain
import chisel3.experimental.util.SerializableModuleElaborator

object GCDTestBenchMain extends SerializableModuleElaborator {
  val topName = "GCDTestBench"

  implicit object PathRead extends TokensReader.Simple[os.Path] {
    def shortName = "path"
    def read(strs: Seq[String]) = Right(os.Path(strs.head, os.pwd))
  }

  @main
  case class GCDTestBenchParameterMain(
    @arg(name = "testVerbatimParameter") testVerbatimParameter: TestVerbatimParameterMain,
    @arg(name = "gcdParameter") gcdParameter:                   GCDParameterMain,
    @arg(name = "timeout") timeout:                             Int,
    @arg(name = "testSize") testSize: Int) {
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
    @arg(name = "resetFlipTick") resetFlipTick: Int) {
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
  def config(
    @arg(name = "parameter") parameter:  GCDTestBenchParameterMain,
    @arg(name = "target-dir") targetDir: os.Path = os.pwd
  ) =
    os.write.over(targetDir / s"${topName}.json", configImpl(parameter.convert))

  @main
  def design(
    @arg(name = "parameter") parameter:  os.Path,
    @arg(name = "target-dir") targetDir: os.Path = os.pwd
  ) = {
    val (firrtl, annos) = designImpl[GCDTestBench, GCDTestBenchParameter](os.read.stream(parameter))
    os.write.over(targetDir / s"${topName}.fir", firrtl)
    os.write.over(targetDir / s"${topName}.anno.json", annos)
  }

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args.toIndexedSeq)
}
