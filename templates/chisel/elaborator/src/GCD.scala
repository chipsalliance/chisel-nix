// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>
package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.{GCD, GCDParameter}
import org.chipsalliance.gcd.elaborator.Elaborator

object GCDMain extends Elaborator {
  @main
  case class GCDParameterMain(
    @arg(name = "width") width:                 Int,
    @arg(name = "useAsyncReset") useAsyncReset: Boolean) {
    require(width > 0, "width must be a non-negative integer")
    require(chisel3.util.isPow2(width), "width must be a power of 2")
    def convert: GCDParameter = GCDParameter(width, useAsyncReset)
  }

  implicit def GCDParameterMainParser: ParserForClass[GCDParameterMain] =
    ParserForClass[GCDParameterMain]

  @main
  def config(@arg(name = "parameter") parameter: GCDParameterMain) = configImpl(
    parameter.convert
  )

  @main
  def design(
    @arg(name = "parameter") parameter:    os.Path,
    @arg(name = "run-firtool") runFirtool: mainargs.Flag,
    @arg(name = "target-dir") targetDir:   os.Path
  ) =
    designImpl[GCD, GCDParameter](parameter, runFirtool.value, targetDir)

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args)
}
