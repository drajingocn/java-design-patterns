package com.iluwatar.command;

import com.aurea.unittest.commons.pojo.Testers;
import com.aurea.unittest.commons.pojo.chain.TestChain;
import com.openpojo.reflection.impl.PojoClassFactory;
import javax.annotation.Generated;
import org.junit.Test;

@Generated("GeneralPatterns")
public class CommandPojoTest {

  @Test
  public void validateCommandToString() {
    TestChain.startWith(Testers.toStringTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Command.class));
  }
}
