// SPDX-License-Identifier: Unlicense
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

package org.chipsalliance.gcd

import chisel3._
import chisel3.experimental.hierarchy.{instantiable, public, Instance, Instantiate}
import chisel3.experimental.{SerializableModule, SerializableModuleParameter}
import chisel3.ltl.Property.{eventually, not}
import chisel3.ltl.{AssertProperty, CoverProperty, Delay, Sequence}
import chisel3.properties.{AnyClassType, Class, Property}
import chisel3.util.circt.dpi.{RawClockedNonVoidFunctionCall, RawUnclockedNonVoidFunctionCall}
import chisel3.util.{Counter, HasExtModuleInline, RegEnable, Valid}
import chisel3.layers.Verification.Assume
import chisel3.ltl.AssumeProperty

object GCDFormalParameter {
  implicit def rwP: upickle.default.ReadWriter[GCDFormalParameter] =
    upickle.default.macroRW
}

/** Parameter of [[GCD]]. */
case class GCDFormalParameter(gcdParameter: GCDParameter) extends SerializableModuleParameter {}

@instantiable
class GCDFormalOM(parameter: GCDFormalParameter) extends Class {
  val gcd   = IO(Output(Property[AnyClassType]()))
  @public
  val gcdIn = IO(Input(Property[AnyClassType]()))
  gcd := gcdIn
}

class GCDFormalInterface(parameter: GCDFormalParameter) extends Bundle {
  val clock = Input(Clock())
  val reset = Input(if (parameter.gcdParameter.useAsyncReset) AsyncReset() else Bool())
  val input = Flipped(Valid(new Bundle {
    val x = UInt(parameter.gcdParameter.width.W)
    val y = UInt(parameter.gcdParameter.width.W)
  }))
  val om    = Output(Property[AnyClassType]())
}

@instantiable
class GCDFormal(val parameter: GCDFormalParameter)
    extends FixedIORawModule(new GCDFormalInterface(parameter))
    with SerializableModule[GCDFormalParameter]
    with ImplicitClock
    with ImplicitReset {
  override protected def implicitClock: Clock         = io.clock
  override protected def implicitReset: Reset         = io.reset
  // Instantiate DUT.
  val dut:                              Instance[GCD] = Instantiate(new GCD(parameter.gcdParameter))
  // Instantiate OM
  val omInstance = Instantiate(new GCDFormalOM(parameter))
  io.om            := omInstance.getPropertyReference.asAnyClassType
  omInstance.gcdIn := dut.io.om

  dut.io.clock := implicitClock
  dut.io.reset := implicitReset

  // LTL Checker
  import Sequence._
  val inputFire:     Sequence = dut.io.input.fire
  val inputNotFire:  Sequence = !dut.io.input.fire
  val outputFire:    Sequence = dut.io.output.valid
  val outputNotFire: Sequence = !dut.io.output.valid
  val inputNotValid: Sequence = dut.io.input.ready && !dut.io.input.valid

  dut.io.input.bits  := io.input.bits
  dut.io.input.valid := io.input.valid

  AssumeProperty(
    inputNotValid |=> not(inputFire),
    label = Some("GCD_ASSUMPTION_INPUT_NOT_VALID")
  )
  AssumeProperty(
    dut.io.input.bits.x === 4.U && dut.io.input.bits.y === 6.U,
    label = Some("GCD_ASSUMPTION_INPUT_4_6")
  )

  AssertProperty(
    inputFire |=> inputNotFire.repeatAtLeast(1) ### outputFire,
    label = Some("GCD_ALWAYS_RESPONSE")
  )
  AssertProperty(
    inputFire |-> not(inputNotFire.repeatAtLeast(1) ### (outputNotFire.and(inputFire))),
    label = Some("GCD_NO_DOUBLE_FIRE")
  )
  AssertProperty(
    outputFire |-> dut.io.output.bits === 2.U,
    label = Some("GCD_RESULT_IS_CORRECT")
  )

  CoverProperty(
    inputNotValid,
    label = Some("GCD_COVER_BACK_PRESSURE")
  )
}
