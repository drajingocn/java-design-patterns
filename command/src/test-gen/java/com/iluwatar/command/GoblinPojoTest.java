package com.iluwatar.command;

import com.aurea.unittest.commons.pojo.Testers;
import com.aurea.unittest.commons.pojo.chain.TestChain;
import com.openpojo.reflection.impl.PojoClassFactory;
import javax.annotation.Generated;
import org.junit.Test;

@Generated("GeneralPatterns")
public class GoblinPojoTest {

  @Test
  public void validateGoblinToString() {
    TestChain.startWith(Testers.toStringTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Goblin.class));
  }

  @Test
  public void validateGoblinConstructors() {
    TestChain.startWith(Testers.constructorTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Goblin.class));
  }
}
