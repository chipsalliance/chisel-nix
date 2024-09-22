// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.{GCDFormal, GCDFormalParameter}
import org.chipsalliance.gcd.elaborator.Elaborator
import org.chipsalliance.gcd.elaborator.GCDMain.GCDParameterMain

object GCDFormalMain extends Elaborator {
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
  def config(@arg(name = "parameter") parameter: GCDFormalParameterMain) =
    configImpl(parameter.convert)

  @main
  def design(
    @arg(name = "parameter") parameter:    os.Path,
    @arg(name = "run-firtool") runFirtool: mainargs.Flag,
    @arg(name = "target-dir") targetDir:   os.Path
  ) =
    designImpl[GCDFormal, GCDFormalParameter](parameter, runFirtool.value, targetDir)

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args)
}
