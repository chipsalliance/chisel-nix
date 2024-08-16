// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2022 Jiuyang Liu <liu@jiuyang.me>

package org.chipsalliance.gcd.elaborator

import mainargs._
import org.chipsalliance.gcd.GCD
import chisel3.panamalib.option._

object Main {
  implicit object PathRead extends TokensReader.Simple[os.Path] {
    def shortName = "path"
    def read(strs: Seq[String]): Either[String, os.Path] = Right(
      os.Path(strs.head, os.pwd)
    )
  }

  implicit def elaborateConfig: ParserForClass[Elaborator] =
    ParserForClass[Elaborator]
  @main
  case class Elaborator(
      @arg(name = "target-dir", short = 't') targetDir: os.Path
  ) {
    def elaborate(gen: () => chisel3.RawModule): Unit = {
      var fir: firrtl.ir.Circuit = null
      var panamaCIRCTConverter: chisel3.panamaconverter.PanamaCIRCTConverter =
        null

      val annos = Seq(
        new chisel3.stage.phases.Elaborate,
        new chisel3.stage.phases.Convert
      ).foldLeft(
        Seq(
          chisel3.stage.ChiselGeneratorAnnotation(gen),
          chisel3.panamaconverter.stage.FirtoolOptionsAnnotation(
            FirtoolOptions(
              Set(
                BuildMode(BuildModeDebug),
                PreserveValues(PreserveValuesModeNamed),
                DisableUnknownAnnotations(true)
              )
            )
          )
        ): firrtl.AnnotationSeq
      ) { case (annos, stage) => stage.transform(annos) }
        .flatMap {
          case firrtl.stage.FirrtlCircuitAnnotation(circuit) =>
            fir = circuit
            None
          case chisel3.panamaconverter.stage
                .PanamaCIRCTConverterAnnotation(converter) =>
            None
          case _: chisel3.panamaconverter.stage.FirtoolOptionsAnnotation => None
          case _: chisel3.stage.DesignAnnotation[_]                      => None
          case _: chisel3.stage.ChiselCircuitAnnotation                  => None
          case a => Some(a)
        }

      os.write(targetDir / s"${fir.main}.fir", fir.serialize)
      os.write(
        targetDir / s"${fir.main}.anno.json",
        firrtl.annotations.JsonProtocol.serialize(annos)
      )
    }
  }

  @main def gcd(elaborator: Elaborator): Unit =
    elaborator.elaborate(() => new GCD)

  def main(args: Array[String]): Unit = ParserForMethods(this).runOrExit(args)
}
