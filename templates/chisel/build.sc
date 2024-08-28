// SPDX-License-Identifier: Apache-2.0
// SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

import mill._
import mill.scalalib._
import mill.define.{Command, TaskModule}
import mill.scalalib.publish._
import mill.scalalib.scalafmt._
import mill.scalalib.TestModule.Utest
import mill.util.Jvm
import coursier.maven.MavenRepository
import $file.dependencies.chisel.build
import $file.common

object deps {
  val scalaVer = "2.13.14"
  val mainargs = ivy"com.lihaoyi::mainargs:0.5.0"
  val oslib = ivy"com.lihaoyi::os-lib:0.9.1"
  val upickle = ivy"com.lihaoyi::upickle:3.3.1"
}

object chisel extends Chisel

trait Chisel extends millbuild.dependencies.chisel.build.Chisel {
  def crossValue = deps.scalaVer
  override def millSourcePath = os.pwd / "dependencies" / "chisel"
}

object gcd extends GCD
trait GCD extends millbuild.common.HasChisel with ScalafmtModule {
  def scalaVersion = T(deps.scalaVer)

  def chiselModule = Some(chisel)
  def chiselPluginJar = T(Some(chisel.pluginModule.jar()))
  def chiselIvy = None
  def chiselPluginIvy = None
}

object elaborator extends Elaborator
trait Elaborator extends millbuild.common.ElaboratorModule {
  def scalaVersion = T(deps.scalaVer)

  def panamaconverterModule = panamaconverter

  def circtInstallPath =
    T.input(PathRef(os.Path(T.ctx().env("CIRCT_INSTALL_PATH"))))

  def generators = Seq(gcd)

  def mainargsIvy = deps.mainargs

  def chiselModule = Some(chisel)
  def chiselPluginJar = T(Some(chisel.pluginModule.jar()))
  def chiselPluginIvy = None
  def chiselIvy = None
}

object panamaconverter extends PanamaConverter
trait PanamaConverter extends millbuild.dependencies.chisel.build.PanamaConverter {
  def crossValue = deps.scalaVer

  override def millSourcePath =
    os.pwd / "dependencies" / "chisel" / "panamaconverter"

  def scalaVersion = T(deps.scalaVer)
}
