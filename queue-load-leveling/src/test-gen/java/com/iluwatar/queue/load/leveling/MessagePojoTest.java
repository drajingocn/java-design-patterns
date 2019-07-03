package com.iluwatar.queue.load.leveling;

import com.aurea.unittest.commons.pojo.Testers;
import com.aurea.unittest.commons.pojo.chain.TestChain;
import com.openpojo.reflection.impl.PojoClassFactory;
import javax.annotation.Generated;
import org.junit.Test;

@Generated("GeneralPatterns")
public class MessagePojoTest {

  @Test
  public void validateMessageGetters() {
    TestChain.startWith(Testers.getterTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Message.class));
  }

  @Test
  public void validateMessageToString() {
    TestChain.startWith(Testers.toStringTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Message.class));
  }

  @Test
  public void validateMessageConstructors() {
    TestChain.startWith(Testers.constructorTester())
        .buildValidator()
        .validate(PojoClassFactory.getPojoClass(Message.class));
  }
}
