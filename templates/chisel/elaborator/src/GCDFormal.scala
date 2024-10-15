// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.{GCDFormal, GCDFormalParameter}
import org.chipsalliance.gcd.elaborator.GCDMain.GCDParameterMain
import chisel3.experimental.util.SerializableModuleElaborator

object GCDFormalMain extends SerializableModuleElaborator {
  val topName = "GCDFormal"

  implicit object PathRead extends TokensReader.Simple[os.Path] {
    def shortName = "path"
    def read(strs: Seq[String]) = Right(os.Path(strs.head, os.pwd))
  }

  @main
  case class GCDFormalParameterMain(
    @arg(name = "gcdParameter") gcdParameter: GCDParameterMain) {
    def convert: GCDFormalParameter = GCDFormalParameter(gcdParameter.convert)
  }

  implicit def GCDParameterMainParser: ParserForClass[GCDParameterMain] =
    ParserForClass[GCDParameterMain]

  implicit def GCDFormalParameterMainParser: ParserForClass[GCDFormalParameterMain] =
    ParserForClass[GCDFormalParameterMain]

  @main
  def config(
    @arg(name = "parameter") parameter:  GCDFormalParameterMain,
    @arg(name = "target-dir") targetDir: os.Path = os.pwd
  ) =
    os.write.over(targetDir / s"${topName}.json", configImpl(parameter.convert))

  @main
  def design(
    @arg(name = "parameter") parameter:  os.Path,
    @arg(name = "target-dir") targetDir: os.Path = os.pwd
  ) = {
    val (firrtl, annos) = designImpl[GCDFormal, GCDFormalParameter](os.read.stream(parameter))
    os.write.over(targetDir / s"${topName}.fir", firrtl)
    os.write.over(targetDir / s"${topName}.anno.json", annos)
  }

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args.toIndexedSeq)
}
