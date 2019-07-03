package com.iluwatar.command;

import com.aurea.unittest.commons.pojo.Testers;
import com.aurea.unittest.commons.pojo.chain.TestChain;
import com.openpojo.reflection.impl.PojoClassFactory;
import javax.annotation.Generated;
import org.junit.Test;

@Generated("GeneralPatterns")
public class TargetPojoTest {

  @Test
  public void validateTargetToString() {
    TestChain.startWith(Testers.toStringTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Target.class));
  }
}
